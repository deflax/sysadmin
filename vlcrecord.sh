#!/bin/bash

while true; do
    today=`date +%Y-%m-%d.%H:%M:%S`
    cvlc -vvv $1 --sout="#std{access=file,mux=ps,dst=out-$today.ts}"
    sleep 5
    done;
    
