#include "smaug/core/backend.h"
#include "smaug/operators/common.h"
#include "smaug/operators/smv/smv_inner_product_op.h"
#include "smaug/operators/smv/smv_inner_product_tiling.h"
#include "smaug/operators/smv/smv_kernels.h"
#include "smaug/operators/smv/smv_accel_pool.h"
#include "smaug/utility/debug_stream.h"

namespace smaug {
namespace smv {
namespace fc {

const int kNumPEs = 8;
const int kNumMaccsPerPE = 8;

}  // namespace fc
}  // namespace smv

// This function iterates the tiles generated by the tiling optimizer and send a
// tile triplet to the hardware kernel for computation. The tile iteration is in
// the following order:
// 1) N: batch-wise tiles in the inputs.
// 2) W: neuron-wise tiles in the weights.
// 3) A: activation-wise tiles in the inputs/weights.
void SmvInnerProductOp::runNWA(TiledTensor& inputs,
                               TiledTensor& weights,
                               TiledTensor& outputs) {
    // Ordinarily, we don't need to tile the outputs. If this fails, it means
    // the inner product has uncommonly large outputs, let's add the output
    // iteration when that happens.
    assert(outputs.size() == 1 &&
           "Inner product outputs tiling not implemented yet!");
    int inputNumTiles = inputs.getShape()[0];
    int inputActTiles = inputs.getShape()[1];
    int weightActTiles = weights.getShape()[1];
    int weightNeuronTiles = weights.getShape()[0];
    auto inputIdx = inputs.startIndex();
    auto weightIdx = weights.startIndex();
    auto outputIdx = outputs.startIndex();
    for (int i = 0; i < numAcceleratorsAvailable; i++) {
        setArrayMemTypeIfSimulating(
                smv::kInnerProductHw + i, "host_a", getInputsMemType());
        setArrayMemTypeIfSimulating(
                smv::kInnerProductHw + i, "host_b", getWeightsMemType());
        setArrayMemTypeIfSimulating(
                smv::kInnerProductHw + i, "host_results", getOutputsMemType());
    }
    SmvAcceleratorPool accelPool(numAcceleratorsAvailable);
    std::vector<int> lastReadInputTileIdx(numAcceleratorsAvailable, -1);
    int currAccelIdx = 0;
    for (int N = 0; N < inputNumTiles; N++) {
        // Usually we are constrained by weights whereas outputs can fit in the
        // scratchpad. This keeps track of finished neurons and will be used by
        // the kernel for correct offset in the outputs scratchpad.
        int finishedNeurons = 0;
        for (int W = 0; W < weightNeuronTiles; W++) {
            // Up to this point, the loop nests do not have data dependency
            // among themselves, and therefore we can run them in parallel. The
            // loop nests beyond this level will need to run in serial, because
            // the input/weight channelwise tiles iteration accumulate results
            // to the same output tile.
            int outputTileIdx = outputIdx(N, 0);
            Tensor* outputTile = outputs[outputTileIdx];
            const TensorShape& outputShape = outputTile->getShape();
            mapArrayToAccel(smv::kInnerProductHw + currAccelIdx, "host_results",
                            outputTile->data<float16>(),
                            outputShape.storageSize() * sizeof(float16));
            int iC = 0, wC = 0;
            // This keeps track of the activation offset of the inputs.
            int actOffset = 0;
            while (iC < inputActTiles && wC < weightActTiles) {
                int inputTileIdx = inputIdx(N, iC);
                int weightTileIdx = weightIdx(W, wC);
                // There is one condition on which the input tile has different
                // number of activations from the weight tile: the inputs don't
                // need tiling on activations while the weights do. In that
                // case, we send the input tile once and keep the input tile
                // stationary in the scrachpad, finishing the weight
                // activation-wise tiles with multiple invocations.
                dout(1) << "Input: " << inputTileIdx
                        << ", weights: " << weightTileIdx
                        << ", output: " << outputTileIdx << "\n";
                Tensor* inputTile = inputs.getTileWithData(inputTileIdx);
                Tensor* weightsTile = weights.getTileWithData(weightTileIdx);
                const TensorShape& inputShape = inputTile->getShape();
                const TensorShape& weightsShape = weightsTile->getShape();
                mapArrayToAccel(smv::kInnerProductHw + currAccelIdx, "host_a",
                                inputTile->data<float16>(),
                                inputShape.storageSize() * sizeof(float16));
                mapArrayToAccel(smv::kInnerProductHw + currAccelIdx, "host_b",
                                weightsTile->data<float16>(),
                                weightsShape.storageSize() * sizeof(float16));
                int inputDims[2] = { inputShape[0], inputShape[1] };
                int weightsDims[2] = { weightsShape[0], weightsShape[1] };
                int outputDims[2] = { outputShape[0], outputShape[1] };
                // If the input and weight tiles belong to the same channel
                // group, then their data will be loaded at the same time into
                // the spads, so we start from the beginning of the tile.
                // Otherwise, we start from the last place we left off from.
                int actStart = (iC == wC) ? 0 : actOffset;
                // If the weights are tiled on activations, this should be set
                // to true for non-first weight tiles to avoid resetting the
                // result buffer.
                bool accumulate = wC > 0;
                // If this is a new input tile, then we need to read it.
                bool readInputs = false;
                if (inputTileIdx != lastReadInputTileIdx[currAccelIdx]) {
                    readInputs = true;
                    lastReadInputTileIdx[currAccelIdx] = inputTileIdx;
                }
                // We only need to send the results back to host memory in the
                // very last invocation.
                bool sendOutputs = (N == inputNumTiles - 1) &&
                                   (W == weightNeuronTiles - 1) &&
                                   (wC == weightActTiles - 1);

                std::unique_ptr<volatile int> finishFlag = invokeKernelNoBlock(
                        currAccelIdx, smv::kInnerProductHw + currAccelIdx,
                        smv_matrix_multiply_transpose_nc_vec_fxp,
                        inputTile->data<float16>(),
                        weightsTile->data<float16>(),
                        outputTile->data<float16>(), smv::spad0, smv::spad1,
                        smv::spad2, inputDims, weightsDims, outputDims,
                        inputShape.getPadding(1), weightsShape.getPadding(1),
                        outputShape.getPadding(1), actStart, finishedNeurons,
                        accumulate, readInputs, sendOutputs, actInfo.function,
                        actInfo.params, &sampling);
                accelPool.addFinishFlag(currAccelIdx, std::move(finishFlag));

                actOffset += weightsTile->getShape()[1];
                if (inputActTiles == weightActTiles) {
                    iC++;
                    wC++;
                } else if (inputActTiles == 1) {
                    wC++;
                } else {
                    assert(false && "The input/weight tiles can have different "
                                    "number of channels only when the inputs "
                                    "don't need activation-wise tiling.");
                }
            }
            finishedNeurons += weights[weightIdx(W, 0)]->getShape()[0];
            currAccelIdx = accelPool.getNextAvailableAccelerator(currAccelIdx);
        }
    }
    // Before we leave, make sure all the accelerators have finished.
    accelPool.joinAll();
}

void SmvInnerProductOp::tile() {
    // This function will tile (if necessary) the input/weight/output tensors
    // of the inner product operator into smaller tensor tiles so that each tile
    // can fit in the corresponding scratchpad of the accelerator.
    tiledTensors = smaug::smv::fc::TilingOptimizer::doTiling(this);
}

void SmvInnerProductOp::run() {
    auto inputs = getInput(Inputs);
    auto weights = getInput(Weights);
    auto outputs = getOutput(Outputs);
    const TensorShape& inputsShape = inputs->getShape();
    const TensorShape& weightsShape = weights->getShape();
    const TensorShape& outputsShape = outputs->getShape();
    assert(inputsShape.getLayout() == DataLayout::NC);
    assert(weightsShape.getLayout() == DataLayout::NC);
    assert(outputsShape.getLayout() == DataLayout::NC);
    dout(2) << *weights << "\n";

    {
        auto stats = gem5::ScopedStats(
                stats::kTensorPrepStart, stats::kTensorPrepEnd);
        tiledTensors[0].copyDataToAllTiles();
        tiledTensors[1].copyDataToAllTiles();
    }

    runNWA(tiledTensors[0], tiledTensors[1], tiledTensors[2]);

    {
        auto stats = gem5::ScopedStats(
                stats::kTensorFinalStart, stats::kTensorFinalEnd);
        tiledTensors[2].untile();
    }
}

}  // namespace smaug
