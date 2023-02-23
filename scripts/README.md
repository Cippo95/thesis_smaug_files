# Scripts folder

I have made some script to have an easier time evaluating simulations:

- `analysis_nvdla.sh` does a total count of ticks of inference, and other stats.
- `main_stats.txt` and `ticks_stats.txt` have to be used with grep to filter stats.txt (large file).

Example of using grep with main_stats.txt (same with ticks_stats.txt):

`grep -f main_stats.txt <simulation/outputs/stats.txt>`

You can redirect the output to a file.

`main_stats.txt` takes what I suppose are the interesting stats.

`ticks_stats.txt` takes just the ticks for all the phases of simulation.

You can see in the tests folder files produced with these methods.

`lenet5_by_layer.sh` and `vgg_by_layer.sh` are scripts to get the execution time in ticks layer by layer of a net.  
They are intended to be used with "just_ticks.txt" of the specified (lenet or vgg) network test.  
With this I can confront the convolutional layers and see if the other ones stay the same...  
I expect some difference due to Aladdin (not really deterministic) nature.
