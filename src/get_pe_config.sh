#!/bin/bash
mkdir ./smaug/operators/$1
mkdir ./smaug/operators/$1/kernels
cp /workspace/smaug/smaug/operators/smv/kernels/convolution_simd.c ./smaug/operators/$1/kernels/
cp /workspace/smaug/smaug/operators/smv/kernels/matrix_multiply.c ./smaug/operators/$1/kernels/
cp /workspace/smaug/smaug/operators/smv/kernels/params.h ./smaug/operators/$1/kernels/
cp /workspace/smaug/smaug/operators/smv/smv_convolution_op.cpp ./smaug/operators/$1/
cp /workspace/smaug/smaug/operators/smv/smv_inner_product_op.cpp ./smaug/operators/$1/
