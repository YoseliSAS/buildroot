#! /bin/bash

# Extract crc32 from uImage file header
# crc32 field is located at offset 24

hexdump -n1 -s24 -e '"%02X"' $1/uImage > $1/uImage.crc32
hexdump -n1 -s25 -e '"%02X"' $1/uImage >> $1/uImage.crc32
hexdump -n1 -s26 -e '"%02X"' $1/uImage >> $1/uImage.crc32
hexdump -n1 -s27 -e '"%02X"' $1/uImage >> $1/uImage.crc32
