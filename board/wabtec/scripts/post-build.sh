#!/bin/sh
# Post-build script for wabtec boards
# $1 = target directory

set -e

TARGET_DIR="$1"

# Remove GDB helper scripts that confuse ldconfig.
# They live under $TARGET_DIR/{lib,usr/lib}/ and
# $TARGET_DIR/usr/share/gdb/auto-load/**/*.
find "$TARGET_DIR" -type f -name "*-gdb.py" -delete 2>/dev/null
echo "post-build: removed *-gdb.py files"

# Generate library version hash for ld.so.cache invalidation.
# Two-level md5: first hash each .so content (deterministic, no timestamps),
# then hash the sorted list of "<md5>  <path>" lines.
(cd "$TARGET_DIR" && \
	find lib usr/lib -name "*.so*" -type f -print0 2>/dev/null \
	| sort -z \
	| xargs -0 md5sum \
	| md5sum | cut -d" " -f1) > "$TARGET_DIR/etc/lib.version"
echo "post-build: generated /etc/lib.version"
