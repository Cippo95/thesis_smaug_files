#Meaning of Configurations
SMV is the name of accelerator from Harvard based on NVDLA's principles.
8x32 for example means 8 processing elements with 32 wide channel operations.

If you look at NVDLA documentation you should see that NVDLA does MACs
operations over a channel of 64, but there are multiple possibile 
configurations; I will set the smaller ones to achieve some fast simulation 
and because of limits in SMAUG about the systolic array, where it can't run at 
16x16 and up because of bugs (as 18 of February 2023). 
