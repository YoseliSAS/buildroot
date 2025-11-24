#!/bin/sh
echo "=== MCF54418 DAC DMA Debug ==="
echo ""
echo "DAC Registers:"
cat /sys/kernel/debug/mcf54418-dac/dac0_regs
echo ""
echo "eDMA Interrupts:"
cat /proc/interrupts | grep eDMA
echo ""
echo "Recent DMA trace events:"
cat /sys/kernel/debug/tracing/trace | grep -E "channel 62|Trigger:" | tail -30
