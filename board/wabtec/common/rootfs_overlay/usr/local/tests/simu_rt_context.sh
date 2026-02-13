#!/bin/bash
cyclictest -p 99 -t1 -i 2500 --policy=fifo -q &
cyclictest -p 93 -t1 -i 100000 --policy=fifo -q &
cyclictest -p 40 -t1 -i 100000 --policy=rr -q &
