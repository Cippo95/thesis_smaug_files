#!/bin/bash
#copy the configuration back and compile 
cp -r ./smaug/operators/$1/* /workspace/smaug/smaug/operators/smv/
cd /workspace/smaug
bash build.sh
