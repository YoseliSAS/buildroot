#!/bin/sh

/bin/mount -t proc proc /proc
/bin/mkdir -p /dev/pts /dev/shm
/bin/mount -a
/bin/echo -1 > /proc/sys/kernel/sched_rt_runtime_us
/bin/ln -sf /proc/self/fd /dev/fd 2>/dev/null
/bin/ln -sf /proc/self/fd/0 /dev/stdin 2>/dev/null
/bin/ln -sf /proc/self/fd/1 /dev/stdout 2>/dev/null
/bin/ln -sf /proc/self/fd/2 /dev/stderr 2>/dev/null
/bin/hostname -F /etc/hostname
/etc/init.d/S01mountdata start
/etc/init.d/S08mountvolatile start
