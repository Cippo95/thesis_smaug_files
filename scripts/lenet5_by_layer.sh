#!/bin/bash
# This script breaks down lenet5 simulation in phases 
# I'm sure it can be done better, but I need something working asap
# This is intended to be used with "just_ticks.txt" of a test

echo -e "LeNet5 ticks/ps per layer:\n"

tensor_sum="# Stats desc: Tensor" 
tensor_end="# Stats desc: Tensor finalization end"
reorder_sum="# Stats desc: Reordering start"
reorder_end="# Stats desc: Reordering end"
one=1
var=0
layer=0
c_list="0 2"
p_list="1 3"

function exists_in_list() {
	LIST=$1
	DELIMITER=$2
	VALUE=$3
	[[ "$LIST" =~ ($DELIMITER|^)$VALUE($DELIMITER|$) ]]
}

while IFS= read -r line
do
	if [[ "$line" = "$tensor_end"* ]]; then
		read line
		var=`expr $var + $(echo $line | awk '{print $2}')`
		if exists_in_list "$c_list" " " $layer; then
			layer_name="C"
		elif exists_in_list "$p_list" " " $layer; then
			layer_name="P"
		else
			layer_name="F"
		fi
		echo $layer_name$layer "	:" $var
		var=0
		layer=`expr $layer + $one`
	elif [[ "$line" = "$tensor_sum"* ]]; then
		read line
		var=`expr $var + $(echo $line | awk '{print $2}')`
	elif [ "$line" = "$reorder_end" ]; then
		read line
		var=`expr $var + $(echo $line | awk '{print $2}')`
		echo "R" "	:" $var
		var=0
	elif [ "$line" = "$reorder_sum" ]; then
		read line
		var=`expr $var + $(echo $line | awk '{print $2}')`
	fi
done < "$1"
echo -e "\nC: Convolution, P: Pooling, R: Reordering, F: Fully Connected."
