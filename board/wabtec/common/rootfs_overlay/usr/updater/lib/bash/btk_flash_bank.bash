#!/bin/bash
#------------------------------------------------------------------------------
# Bash toolkit flash bank helpers
#
# This file shall be sourced
#
# External variables used
#   kernelFile
#   newKernelCrc16
#   kernelCrc16File
#   rootfsFile
#   newRootfsCrc16
#   rootfsCrc16File
#   newKernelCrc16
#   newRootfsCrc16
#
# Author R.BEAUJOUAN
#------------------------------------------------------------------------------

#-----------------------------------------------------------------------------
# MTD map
declare -r mtdKernel1=/dev/mtd1
declare -r mtdRootFS1=/dev/mtd2
declare -r mtdKernel2=/dev/mtd4
declare -r mtdRootFS2=/dev/mtd5

# File used to provide params between flash_bank and flash_confirm_bank functions calls
declare -r tmpConfirmBankFile=/tmp/confirmbank

#-----------------------------------------------------------------------------
# Helpers
#-----------------------------------------------------------------------------
function extract_field_from_file()
{
  InputFile=$1
  Field=$2

  grep $Field $InputFile | sed "s/^$Field\(.*\)$/\1/"
}

# Flash file ($1) to mtd device ($2)
function flash_mtd(){
   local _file=$1
   local _mtd=$2
   local _crc=$3

   if ! btk_flash_mtd_device ${_file} ${_mtd} ${_crc} ; then
      btk_print "Error at first attempt !"
      btk_print "Second try..."

      if ! btk_flash_mtd_device ${_file} ${_mtd} ${_crc} ; then
         btk_error "btk_flash_mtd_device failed"
      fi
   fi
}

#------------------------------------------------------------------------------
# Flash a bank and set status variable
# Parameters:
#   $1 bank number
# External variables used
#   kernelFile
#   newKernelCrc16
#   kernelCrc16File
#   rootfsFile
#   newRootfsCrc16
#   rootfsCrc16File
#   newPackageCrc16
#------------------------------------------------------------------------------
function flash_bank()
{
    local bank_nb=$1
  # Sanity check
  if [[ "${bank_nb}" != "1" ]] && [[ "${bank_nb}" != "2" ]]
  then
    btk_print "Invalid bank number ${bank_nb}"
    return 1
  fi

  # Remove potentially existing bank Confirmation file awaiting for bank flashing result
  rm -f $tmpConfirmBankFile

    local other_bank_nb=0;

    if [[ "${bank_nb}" == "1" ]] ; then
        _mtdKernel=${mtdKernel1}
        _mtdRootFS=${mtdRootFS1}
        other_bank_nb=2;
    else
        _mtdKernel=${mtdKernel2}
        _mtdRootFS=${mtdRootFS2}
        other_bank_nb=1;
    fi

    # Flash kernel and rootfs
    btk_print "Programming Kernel..."
    flash_mtd ${kernelFile} ${_mtdKernel} ${newKernelCrc16}
    btk_print "Done"
    btk_print "Programming rootfs..."
    flash_mtd ${rootfsFile} ${_mtdRootFS} ${newRootfsCrc16}
    btk_print "Done."

  # Tell fyinstaller to confirm bank if everything went correct
  btk_print "Signal that bank confirmation is needed in <$tmpConfirmBankFile>..."

  echo "bank_nb=${bank_nb}" > $tmpConfirmBankFile
  echo "newKernelCrc16=${newKernelCrc16}" >> $tmpConfirmBankFile
  echo "newRootfsCrc16=${newRootfsCrc16}" >> $tmpConfirmBankFile
  echo "newRootfsFileSize=$(stat -c %s ${rootfsFile})" >> $tmpConfirmBankFile
  echo "newRootfsFileType=${inputFSType}" >> $tmpConfirmBankFile
  echo "newPackageCrc16=${newPackageCrc16}" >> $tmpConfirmBankFile

    btk_print "Done."

    btk_print "Removing temporary files..."
    # remove temporary files
    rm ${kernelFile}
    rm ${rootfsFile}
    rm ${kernelCrc16File}
    rm ${rootfsCrc16File}
    btk_print "Done."
}

#------------------------------------------------------------------------------
# Confirm a bank and set the other one to blank
# $1 confirmation file containing following parameters:
# bank_nb=[1;2]
# newKernelCrc16=16 bits Hex Format
# newRootfsCrc16=16 bits Hex Format
# newRootfsFileSize=Dec Format
# newRootfsFileType=[jffs2|ext2]
# newPackageCrc16=16 bits Hex Format
#------------------------------------------------------------------------------
function flash_confirm_bank()
{
    local other_bank_nb=0;

  # Sanity check
  if [[ ! -e ${tmpConfirmBankFile} ]]
  then
    return -1
  fi

  # Params extract
  bank_nb=$(extract_field_from_file $tmpConfirmBankFile "bank_nb=" )
  newKernelCrc16=$(extract_field_from_file $tmpConfirmBankFile "newKernelCrc16=" )
  newRootfsCrc16=$(extract_field_from_file $tmpConfirmBankFile "newRootfsCrc16=" )
  newRootfsFileSize=$(extract_field_from_file $tmpConfirmBankFile "newRootfsFileSize=" )
  newRootfsFileType=$(extract_field_from_file $tmpConfirmBankFile "newRootfsFileType=" )
  newPackageCrc16=$(extract_field_from_file $tmpConfirmBankFile "newPackageCrc16=" )

  # Sanity check
  if [[ "${bank_nb}" != "1" ]] && [[ "${bank_nb}" != "2" ]]
  then
    btk_print "Invalid bank number ${bank_nb}"
    return 1
  fi

    if [[ "${bank_nb}" == "1" ]] ; then
        other_bank_nb=2;
    else
        other_bank_nb=1;
    fi

    btk_print "Bank confirmation..."

  # Set bank as confirmed
  fw_setenv bank${bank_nb}_status confirmed
  fw_setenv bank${other_bank_nb}_status blank
  # Set crc
  fw_setenv kernel_crc16 "${newKernelCrc16}"
  fw_setenv rootfs_crc16 "${newRootfsCrc16}"

  fw_setenv package${bank_nb}_crc16 "${newPackageCrc16}"
  fw_setenv package${other_bank_nb}_crc16 "?"

  fw_setenv kernel${bank_nb}_crc16 "${newKernelCrc16}"
  fw_setenv rootfs${bank_nb}_crc16 "${newRootfsCrc16}"
  fw_setenv rootfs${bank_nb}_img_sz "${newRootfsFileSize}"
  fw_setenv kernel${other_bank_nb}_crc16 "?"
  fw_setenv rootfs${other_bank_nb}_crc16 "?"

  fw_setenv bootargs_rootfs_type "$newRootfsFileType"
  fw_setenv bootargs_rootfs_img rootfs."$newRootfsFileType"

  btk_print "Done."

  btk_print "Bank #${bank_nb} is now confirmed"
  btk_print "Bank #${other_bank_nb} is now blank"
}

#------------------------------------------------------------------------------
# Check if bank confirmation is requested
# NB: flash_confirm_bank shall be called only if all installation is SUCCESS and a confirmation is requested
# return 0 if bank confirmation is requested, else 1
#------------------------------------------------------------------------------
function flash_is_bank_confirmation_requested()
{
  bankConfirmationIsRequested=1
  # Check if ConfirmBankFile exists
  if [[ -s "${tmpConfirmBankFile}" ]]
  then
    bankConfirmationIsRequested=0
  fi

  return $bankConfirmationIsRequested
}
