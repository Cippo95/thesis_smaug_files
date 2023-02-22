# Source folder
Here the files I have modified in SMAUG for my simulations.

## Configs folder
It contains:
- `smv-accel_<pe_config>.cfg` that configures: 
  - The partitioning of arrays/registers
  - The optimization of the kernels to achieve the right parallelism of functional units
- CACTI files to extimate power consumption from memories.

## SMAUG folder

I need to modify sources and recompile SMAUG to achieve different configurations.

I use the same folder structure of SMAUG.

I also modified the matrix multiply kernel, because from my tests the original one can't parallelize functional units correctly.

Run: `bash set_pe_configs.sh smv_<pe_config>` to copy the configurations files and build SMAUG.  
For this to work correctly you need `build.sh` script to compile SMAUG and SMAUG-instrumented in SMAUG's root folder, it contains:
>#!bin/bash  
>make all -j$(nproc)  
>make tracer -j$(nproc)  

Being in SMAUG's root folder it wasn't copied here, sorry.

`get_pe_configs.sh` is deprecated: it was made because at first I thought I would modify the sources and copy back the configuration (giving it a name); at the end I have directly modified the code from this folder and copied it back to SMAUG's sources (it is smarter).

## Aladdin configuration

The original `aladdin_se.py` in gem5-Aladdin and SMAUG lacks the code to set the cpu clock: in simulation it gets the system clock.

I have fixed this behavior (simply following gem5 guidelines) and share my configuration.

Use it to replace the file here: `/workspace/gem5-aladdin/configs/aladdin/aladdin_se.py`
