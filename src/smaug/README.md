# SMAUG folder... some more detail

## Configuring the processing elements (PE)

SMAUG models NVDLA dataflow as 8 PEs with a channel width of 32.

This configuration is achieved with `NUM_PE_INSTS` and `NUM_MACC_INSTS` costants in:  
`/workspace/smaug/smaug/operators/smv/kernels/params.h`

Changing the costants you will need to adjust the arrays that depend on them in:  
`/workspace/smaug/smaug/operators/smv/kernels/convolution_simd.c`  
`/workspace/smaug/smaug/operators/smv/kernels/matrix_multiply.c`  
I have experimented with arrays made of the right dimension at runtime (seems smart),
with a for loop populating (with zeros) the arrays... but it adds some cycle to
the accelerator, not that much tbh but I think that it is better to avoid that.

Furthermore tiling needs `kNumPEs` and `kNumMaccsPerPE` to be adjusted in:  
`/workspace/smaug/smaug/operators/smv/smv_convolution_op.cpp`  
`/workspace/smaug/smaug/operators/smv/smv_inner_product_op.cpp`  

You can find in this folder all my files.  
I use the same SMAUG folder structure to easily copy back the files with a script (`set_pe_configuration.sh`).

## Further modifications

I have modified matrix_multiply.c in:  
`/workspace/smaug/smaug/operators/smv/kernels/matrix_multiply.c`
From my tests it wasn't able to use all the multipliers (so the MACs) in
the sistem for some reason (this also lead to modify smv-accel<pe_config>.cfg).

The license of all these files of course stays as the original SMAUG sources, so BSD-3 (I think?).
