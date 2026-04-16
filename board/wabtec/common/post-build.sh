#!/bin/sh
# Post-build script for wabtec boards
# $1 = target directory

TARGET_DIR="$1"

# Remove GDB helper scripts that confuse ldconfig
rm -f "$TARGET_DIR"/lib/*-gdb.py "$TARGET_DIR"/usr/lib/*-gdb.py
echo "post-build: removed *-gdb.py files"

# Generate library version hash for ld.so.cache invalidation
# This hash changes when libraries are added/removed/updated
(cd "$TARGET_DIR" && find lib usr/lib -name '*.so*' -type f 2>/dev/null | sort | xargs ls -l 2>/dev/null | md5sum | cut -d' ' -f1) > "$TARGET_DIR/etc/lib.version"
echo "post-build: generated /etc/lib.version"
