#!/bin/bash

# Increase real-time runtime limit
#RT_RUNTIME_FILE="/proc/sys/kernel/sched_rt_runtime_us"
#echo 950000 > "$RT_RUNTIME_FILE"

declare -A priorities=(
    ["irq/178-UART"]=99
    ["irq/68-s2tos0"]=98
    ["eDMA-14"]=97
    ["eDMA-15"]=96
    ["eDMA-7"]=94
    ["irq/100-enet"]=40
    ["irq/104-enet"]=40
    ["ubifs_bgt0_0"]=30
    ["ubi_bgt0d"]=30
)

ps -eo pid,args | tail -n +2 | while read -r pid line; do
    for pattern in "${!priorities[@]}"; do
        if [[ "$line" == *"$pattern"* ]]; then
            prio=${priorities[$pattern]}
            echo "Setting priority $prio for PID $pid ($pattern)"
            chrt -f -p "$prio" "$pid" &
        fi
    done
done
wait

