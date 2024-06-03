#!/bin/sh

# This script is executed to add padding to the uImage to align it on
# BR2_TARGET_ROOTFS_JFFS2_EBSIZE.

# Once the padding is done, it calculates crc16 and crc32 checksums for the uImage.

# Display the arguments passed to the script
echo "post-image.sh $@"

# Example: post-image.sh /home/jm/Projects/wabtec/buildroot/output/images /home/jm/Projects/wabtec/buildroot/configs/wabtec_dlcnext_defconfig
# First argument is the output directory
# Second argument is the configuration file

output_dir=$1
config_file=$2

loadaddr="0x41000000"
entryaddr="0x41002000"

# Get the basedir of the script from configuration BR2_ROOTFS_POST_IMAGE_SCRIPT in config_file
# ex: BR2_ROOTFS_POST_IMAGE_SCRIPT="board/wabtec/scripts/post-image.sh"
# The basedir is "board/wabtec/scripts"
# If there is no value, then use the default "board/wabtec/scripts"
basedir=$(grep "BR2_ROOTFS_POST_IMAGE_SCRIPT" $config_file | cut -d'"' -f2 | xargs dirname)
if [ -z "$basedir" ]; then
    basedir="board/wabtec/scripts"
fi
echo "basedir=$basedir"

# Display the BR2_TARGET_ROOTFS_JFFS2_EBSIZE value in config_file
# If there is no value, then use the default "0x20000"
ebsize=$(grep "BR2_TARGET_ROOTFS_JFFS2_EBSIZE" $config_file | cut -d'"' -f2)
if [ -z "$ebsize" ]; then
    ebsize="0x20000"
fi
echo "BR2_TARGET_ROOTFS_JFFS2_EBSIZE=$ebsize"

uimage="$output_dir/uImage"
# Remove the uImage if it already exists
if [ -f "$uimage" ]; then
    rm -f "$uimage"
fi

# Generate a uImage from the vmlinux file
# Get the kernel defconfig file to grep the load address and entry address
linuxversion=$(grep "BR2_LINUX_KERNEL_VERSION" $config_file | cut -d'"' -f2)
if [ -z "$linuxversion" ]; then
    linuxversion="6.1.83-rt10"
fi
echo "linuxversion=$linuxversion"
mkimage -A m68k -O linux -T kernel -C none -a $loadaddr -e $entryaddr -n $linuxversion -d ${output_dir}/vmlinux ${uimage}

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

# Calculate the crc16 and crc32 checksums for the uImage
# crc16:
# @$(call MESSAGE,"Generating CRC16 checksum files")
# @rm -f $(BINARIES_DIR)/*.crc16
# @rm -f $(BINARIES_DIR)/*.crc32
# @python support/scripts/crc16.py -w $(BINARIES_DIR)/*
# @$(call MESSAGE,"Generating CRC32 checksum files for uImage")
# @support/scripts/mkCrc32.sh $(BINARIES_DIR)

echo "Generating CRC16 checksum files"
rm -f "$output_dir"/*.crc16
rm -f "$output_dir"/*.crc32
python ${basedir}/crc16.py -w "${output_dir}/*"
echo "Generating CRC32 checksum files for uImage"
${basedir}/mkCrc32.sh "$output_dir"
