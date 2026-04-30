#!/bin/sh
# Post-build script for wabtec boards
# $1 = target directory

set -e

TARGET_DIR="$1"
OUTPUT_DIR="$(cd "$TARGET_DIR/.." && pwd -P)"
HOST_DIR="${OUTPUT_DIR}/host"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
BR2_CONFIG="${CONFIG_DIR:-$OUTPUT_DIR}/.config"

# Read BR2_* boolean flags from Buildroot .config.
# Buildroot 2025.11 does not expose BR2_* via env to post-build hooks
# (see package/Makefile.in EXTRA_ENV); reading .config is the canonical way.
br2_is_set() {
	grep -q "^${1}=y" "$BR2_CONFIG" 2>/dev/null
}

# Remove GDB helper scripts that confuse ldconfig.
# They live under $TARGET_DIR/{lib,usr/lib}/ and
# $TARGET_DIR/usr/share/gdb/auto-load/**/*.
find "$TARGET_DIR" -type f -name "*-gdb.py" -delete 2>/dev/null
echo "post-build: removed *-gdb.py files"

# Pre-generate /etc/ld.so.cache at build time using the host ldconfig.
# The rootfs library layout is static, so the cache is valid for every
# boot and eliminates the ldconfig run at first boot (~7s gain).
if [ -x "${HOST_DIR}/bin/ldconfig" ]; then
	"${HOST_DIR}/bin/ldconfig" -r "$TARGET_DIR" -C /etc/ld.so.cache -X
	echo "post-build: pre-generated /etc/ld.so.cache"
fi

# Generate library version hash for ld.so.cache invalidation.
# Two-level md5: first hash each .so content (deterministic, no timestamps),
# then hash the sorted list of "<md5>  <path>" lines.
(cd "$TARGET_DIR" && \
	find lib usr/lib -name "*.so*" -type f -print0 2>/dev/null \
	| sort -z \
	| xargs -0 md5sum \
	| md5sum | cut -d" " -f1) > "$TARGET_DIR/etc/lib.version"
echo "post-build: generated /etc/lib.version"

# Generate the multi-volume UBI data image and embed data.ubi.gz under
# $TARGET_DIR/usr/share/ so that S01mountdata can flash it on the first
# boot (or on reflash) when the data MTD is empty.
#
# The copy lands directly in $TARGET_DIR rather than in the source
# rootfs_overlay tree because the overlay is copied to target before
# post-build runs; writing to the overlay would only ship the artifact
# in the *next* build, never the current one.
if [ -x "${SCRIPT_DIR}/gen-datafs-ubi-multi.sh" ]; then
	echo "post-build: generating multi-volume data.ubi"
	"${SCRIPT_DIR}/gen-datafs-ubi-multi.sh" "$OUTPUT_DIR"
	mkdir -p "$TARGET_DIR/usr/share"
	cp "${OUTPUT_DIR}/images/data.ubi.gz" "$TARGET_DIR/usr/share/data.ubi.gz"
	echo "post-build: data.ubi.gz embedded in $TARGET_DIR/usr/share/"
fi
