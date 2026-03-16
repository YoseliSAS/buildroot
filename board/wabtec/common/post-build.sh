#!/bin/sh
# Post-build script for wabtec boards
# $1 = target directory

TARGET_DIR="$1"

# Use busybox hush as /bin/sh for faster boot (instead of bash)
# bash is still available as /bin/bash for scripts that need it
if [ -e "$TARGET_DIR/bin/busybox" ]; then
    ln -sf busybox "$TARGET_DIR/bin/sh"
    echo "post-build: /bin/sh -> busybox (for faster boot)"
fi

# Remove buildroot's default nginx init script (we use S80nginx from overlay)
rm -f "$TARGET_DIR/etc/init.d/S50nginx"
echo "post-build: removed S50nginx (using S80nginx)"

# Remove GDB helper scripts that confuse ldconfig
rm -f "$TARGET_DIR"/lib/*-gdb.py "$TARGET_DIR"/usr/lib/*-gdb.py
echo "post-build: removed *-gdb.py files"

# Generate library version hash for ld.so.cache invalidation
# This hash changes when libraries are added/removed/updated
(cd "$TARGET_DIR" && find lib usr/lib -name '*.so*' -type f 2>/dev/null | sort | xargs ls -l 2>/dev/null | md5sum | cut -d' ' -f1) > "$TARGET_DIR/etc/lib.version"
echo "post-build: generated /etc/lib.version"
