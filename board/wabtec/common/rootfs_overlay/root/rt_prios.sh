#!/bin/sh

# Increase real-time runtime limit
#RT_RUNTIME_FILE="/proc/sys/kernel/sched_rt_runtime_us"
#echo 950000 > "$RT_RUNTIME_FILE"

# Function to set priorities for processes
set_priority() {
    local priority=$1
    local pattern=$2

    # Find PIDs matching the pattern
    pids=$(ps | grep -E "$pattern" | grep -v "grep" | awk '{print $1}')
    
    if [ -n "$pids" ]; then
        for pid in $pids; do
            echo "Setting priority $priority for PID $pid ($pattern)"
            chrt -f -p "$priority" "$pid"
        done
    else
        echo "No processes found matching pattern: $pattern"
    fi
}

# Apply priorities
set_priority 99 "irq/178-UART"
set_priority 92 "irq/92-UART"
set_priority 93 "eDMA-6"
set_priority 93 "eDMA-7"
set_priority 98 "irq/182-dspi-sl"
set_priority 98 "eDMA-14"
set_priority 98 "eDMA-15"
set_priority 40 "irq/100-enet"
set_priority 40 "irq/104-enet"
set_priority 96 "irq/68-s2tos0"
set_priority 30 "ubifs_bgt0_0"
set_priority 30 "ubi_bgt0d"

exit 0
