#!/bin/bash

#Gem5's stats are on the 2nd column, Aladdin 3rd or 4th so I make 3 functions
#to make the overall sum

sum_2nd_col() {
	grep $1 $2 | awk '{ sum+=$2 } END {OFMT="%.0f"; print sum}'
}

sum_3rd_col() {
	grep $1 $2 | awk '{ sum+=$3 } END {OFMT="%.0f"; print sum}'
}

sum_4th_col() {
	grep $1 $2 | awk '{ sum+=$4 } END {OFMT="%.0f"; print sum}'
}
echo "*************************************************************************"
echo "Author: Filippo Landi"
echo -e "\nTicks are equal to picoseconds (ps), 10^(-12) seconds."
echo "E.G clock frequency of 1GHz (clock period of 1ns) is 1000 ticks/ps."
echo -e 
echo "Systolic array stats are generated only if present!"
echo -e
echo "CPU is quiesced (disconnected from power) when accelerators are running."
echo "*************************************************************************"

echo -e "\n[Raw total statistics]\n" 
# simulation ticks 
simTicks=$(sum_2nd_col sim_ticks $1/outputs/stats.txt)
echo "Ticks simulated:   " $simTicks
# cpu cycles
cpuCycles=$(sum_2nd_col system.switch_cpus.numCycles $1/outputs/stats.txt) 
echo "CPU cycles simul.: " $cpuCycles
# cpu idle cycles
cpuIdleCycles=$(sum_2nd_col system.switch_cpus.idleCycles $1/outputs/stats.txt)
echo "CPU idle cycles:   " $cpuIdleCycles
# cpu quiesce cycles
cpuQuiesceCycles=$(sum_2nd_col system.switch_cpus.quiesceCycles $1/outputs/stats.txt)
echo "CPU quiesced cyc.: " $cpuQuiesceCycles
# aladdin cycles
cycle="^Cycle"
aladdinCycles=$(sum_3rd_col $cycle $1/stdout) 
echo "Aladdin cycles:    " $aladdinCycles
# dma setup cycles
dmaSetupCycles=$(sum_2nd_col system.acc0_datapath.dma_setup $1/outputs/stats.txt)
echo "DMA setup cycles:  " $dmaSetupCycles
# total databus transfer ticks
totBusTicks=$(sum_2nd_col $system.mem_ctrls.totBusLat $1/outputs/stats.txt)
echo "Bus transfer ticks:" $totBusTicks
# systolic array cycles
systolicCycles=$(sum_2nd_col system.systolic_array_acc.numCycles $1/outputs/stats.txt)
echo "Systolic ticks:    " $systolicCycles

echo -e "\n[Clock speeds in GHz]\n"
# print clock speeds
cpuClock=$(grep -m 1 system.cpu_clk_domain.clock $1/outputs/stats.txt | awk '{print $2}')
cpuClockGHz=$(echo $cpuClock | awk '{print 1000/$1}')
echo "CPU              " $cpuClockGHz
# print datapath clock
dataClock=$(grep -m 1 system.acc0_datapath.clk_domain.clock $1/outputs/stats.txt | awk '{print $2}')
dataClockGHz=$(echo $dataClock | awk '{print 1000/$1}')
echo "Aladdin:         " $dataClockGHz
systemClock=$(grep -m 1 system.clk_domain.clock $1/outputs/stats.txt | awk '{print $2}')
systemClockGHz=$(echo $systemClock | awk '{print 1000/$1}')
echo "System/Sys.Array:" $systemClockGHz

echo -e "\n[Everything in ticks!]\n" 
# inference ticks
inferenceTicks=$(echo $simTicks | awk '{OFMT="%.0f"; print $1}')
echo "Inference:    " $inferenceTicks 
# cpu on ticks 
cpuOnTicks=$(echo $cpuCycles $cpuClock | awk '{OFMT="%.0f"; print $1*$2}')
echo "CPU ticks:    " $cpuOnTicks
cpuIdleTicks=$(echo $cpuIdleCycles $cpuClock | awk '{OFMT="%.0f"; print $1*$2}')
echo "CPU idle:     " $cpuIdleTicks
cpuQuiesceTicks=$(echo $cpuQuiesceCycles $cpuClock | awk '{OFMT="%.0f"; print $1*$2}')
echo "CPU quiesce:  " $cpuQuiesceTicks
aladdinTicks=$(echo $aladdinCycles $dataClock | awk '{OFMT="%.0f"; print $1*$2}')
echo "Aladdin:      " $aladdinTicks
dmaSetupTicks=$(echo $dmaSetupCycles $dataClock | awk '{OFMT="%.0f"; print $1*$2}')
echo "DMA setup:    " $dmaSetupTicks
totBusTicks=$(echo $totBusTicks | awk '{OFMT="%.0f"; print $1}')
echo "Bus transfer: " $totBusTicks
systolicTicks=$(echo $systolicCycles | awk '{OFMT="%.0f"; print $1}')
echo "Systolic:     " $systolicTicks

echo -e "\n[Equivalent time in ms]\n" 
psToMs=1000000000
# inference time
inferenceTime=$(echo $simTicks $psToMs | awk '{print $1/$2}')
echo "Inference:    " $inferenceTime 
# cpu time 
cpuOnTime=$(echo $cpuCycles $cpuClock $psToMs | awk '{print $1*$2/$3}')
echo "CPU time:     " $cpuOnTime
cpuIdleTime=$(echo $cpuIdleCycles $cpuClock $psToMs | awk '{print $1*$2/$3}')
echo "CPU idle:     " $cpuIdleTime
cpuQuiesceTime=$(echo $cpuQuiesceCycles $cpuClock $psToMs | awk '{print $1*$2/$3}')
echo "CPU quiesce:  " $cpuQuiesceTime
aladdinTime=$(echo $aladdinCycles $dataClock $psToMs | awk '{print $1*$2/$3}')
echo "Aladdin:      " $aladdinTime
dmaSetupTime=$(echo $dmaSetupCycles $dataClock $psToMs | awk '{print $1*$2/$3}')
echo "DMA setup:    " $dmaSetupTime
totBusTime=$(echo $totBusTicks $psToMs | awk '{print $1/$2}')
echo "Bus transfer: " $totBusTime
systolicTime=$(echo $systolicCycles $psToMs | awk '{print $1/$2}')
echo "Systolic:     " $systolicTime
