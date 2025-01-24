#!/bin/sh

# This script is executed to add padding to the uImage to align it on
# BR2_TARGET_ROOTFS_JFFS2_EBSIZE.

output_dir=$1
shift
jffs2_opts=$@

echo "jffs2_opts=$jffs2_opts"

basedir=$(dirname $0)

# If there is no value, then use the default "0x20000"
# It should be in the jffs2_opts in the form "-e 0x20000"
ebsize="0x20000"
for arg in $jffs2_opts
do
    if [ "$arg" = "-e" ]; then
        ebsize=$(echo $jffs2_opts | cut -d' ' -f2)
    fi
done
echo "ebsize=$ebsize"

uimage="${output_dir}/uImage"

# Add padding to the uImage to align it on BR2_TARGET_ROOTFS_JFFS2_EBSIZE
# The uImage is padded with 0x00 bytes

# Get the size of the uImage
uimage_size=$(stat -c%s "$uimage")

# Check if the current size is already a multiple of ebsize
if [ $(($uimage_size % $ebsize)) -eq 0 ]; then
    echo "No padding needed"
else
    # Display the size before padding
    echo "Size before padding: $uimage_size"

    # Calculate the padding size
    padding_size=$(($ebsize - $uimage_size % $ebsize))

    # Add padding to the uImage
    dd if=/dev/zero bs=1 count=$padding_size >> "$uimage"

    # Get the new size of the uImage
    new_uimage_size=$(stat -c%s "$uimage")

    # Display the size after padding
    echo "Size after padding: $new_uimage_size"
fi
