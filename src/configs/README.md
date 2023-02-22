This folder has the configuration files I used.
There are also folders with the source files that you need to change to try
different processing elements configurations of convolution with nvdla dataflow.

You need to change in /workspace/smaug/smaug/operators/smv:
1)smv_convolution_op.cpp
2)/kernel/params.h
3)/kernel/convolution_simd.c

For the CPU only execution you need to change: 
/workspace/smaug/smaug/operators/common.h
