#Configuring the processing elements
SMAUG models NVDLA dataflow as 8 PEs with a channel width of 32.

This configuration is achieved with NUM_PE_INSTS and NUM_MACC_INSTS in:
/workspace/smaug/smaug/operators/smv/kernels/params.h

Since the registers of the PEs are assigned with their size you need
to also modify the arrays with the correct size in:
/workspace/smaug/smaug/operators/smv/kernels/convolution_simd.c
/workspace/smaug/smaug/operators/smv/kernels/matrix_multiply.c
I have experimented with arrays made of the right dimension at runtime,
with a for loop for assignement of values... but it adds some cycle to
the accelerator so I think it is better to avoid that.

Furthermore tilings needs kNumPEs and kNumMaccsPerPE to be adjusted in:
/workspace/smaug/smaug/operators/smv/smv_convolution_op.cpp
/workspace/smaug/smaug/operators/smv/smv_inner_product_op.cpp

I copy in this folder my modified source files for different configurations to 
ease the reproducibility of my tests.

#Further modifications

I have also modified matrix_multiply.c in:
/workspace/smaug/smaug/operators/smv/kernels/matrix_multiply.c
Since from my tests it wasn't able to use all the multipliers (so the MACs) in
the sistem for some reason (had to modify also smv-accel.cfg to work).

I have noticed that SMAUG didn't set the CPU clock correctly and after some
investigation I have discovered that gem5-Aladdin had some missing
configuration lines of code.
So I have modified with the appropriate configuration:
/workspace/gem5-aladdin...

The license of all these files stays as the original SMAUG sources.
