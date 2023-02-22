analysis_nvdla.sh does a total count of ticks of inference and other stuff.

main_stats.txt and ticks_stats.txt have to be used with grep on /outputs/stats
in the network test folder. 
With main_stats you get what I suppose are the main stats to look.
With ticks_stats you just get the ticks per layer (divided in preparation and 
finalization phases).
