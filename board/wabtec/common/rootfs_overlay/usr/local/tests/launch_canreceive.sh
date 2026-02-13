#!/bin/bash
time chrt -r 30 candump -td -c -d -e can1 2>&1 | grep -i drop > /tmp/canlog.txt &
