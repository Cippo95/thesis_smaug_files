# Operators folder

Meaning of a configuration name:
- 'SMV' is the name of accelerator from Harvard based on NVDLA's principles.
- '8x32' for example means 8 processing elements with 32 wide channel operations.

Looking at NVDLA documentation there are [multiple possibile configurations](http://nvdla.org/primer.html#example-area-and-performance-with-nvdla).  

I use the smaller configurations (4x8, 4x16, 8x8) because of limits in SMAUG's systolic array:  
it can't run at 16x16 and up because of bugs (as 18 of February 2023).  

Since I want to compare the NVDLA dataflow to the systolic array with a similar number of multipliers: 

- NVDLA 4x8 is compared to systolic array 4x8
- NVDLA 4x16 is compared to systolic array 8x8
- NVDLA 8x8 is compared to systolic array 8x8

But I also share the default SMAUG configuration (NVDLA 8x32).
