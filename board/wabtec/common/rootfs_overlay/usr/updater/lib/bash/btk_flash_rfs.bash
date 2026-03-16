#!/bin/bash

#------------------------------------------------------------------------------
# Flash the kernel and RFS (rootfs) in the input tar.gz file
#   extention .krf, for Kernel-RootFs
#
# Author MHN
#------------------------------------------------------------------------------

#-----------------------------------------------------------------------------
# Parameters
# $1 : input file
# $2 : filesystem [ext2|jffs2]
#-----------------------------------------------------------------------------
: ${UPDATER_HOME:=/usr/updater}
declare -r VERSION_RFS="1.0"
export PATH=${UPDATER_HOME}/lib/bash:${UPDATER_HOME}/installers${PATH:+:${PATH}}

# Input file type
declare -r  inputFile=$1
if [ "x$2" == "xjffs2" ]; then
    declare -r  inputFSType=jffs2
elif [ "x$2" == "xext2" ]; then
    declare -r  inputFSType=ext2
else
    btk_print "RFS Image type not recognized (file $1 type $2). Try ext2..."
    declare -r  inputFSType=ext2
fi

# Extract install dir from input file string
fullpath="$1"
filename="${fullpath##*/}"                              # Strip longest match of */ from start
install_dir="${fullpath:0:${#fullpath} - ${#filename}}" # Substring from 0 thru pos of filename

# Required tools list
declare -r  requiredTools="tar fw_printenv fw_setenv"

declare newKernelCrc16=
declare newRootfsCrc16=

# Extracted binaries path
declare -r packageCrc16File="$install_dir/package.crc16"
declare -r kernelFile="$install_dir/uImage"
declare -r kernelCrc16File=${kernelFile}".crc16"
declare -r rootfsFile="$install_dir/rootfs.$inputFSType"
declare -r rootfsCrc16File=${rootfsFile}".crc16"
declare -r crc16Processor="/usr/DLC2ng/crc16CCITT/crc16CCITT"

# local variables
declare currentKernelCrc16=""
declare currentRootfsCrc16=""
declare newKernelCrc16=""
declare newRootfsCrc16=""
declare updateRequiered=0
declare errorDetected=0

#-----------------------------------------------------------------------------
# Toolkit import
#-----------------------------------------------------------------------------

# Load toolkit
source bash_toolkit.bash
source btk_flash_bank.bash

#-----------------------------------------------------------------------------
# Helpers
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
# Start
#-----------------------------------------------------------------------------

btk_print "Starting $0 version ${VERSION_RFS}"

#
# Sanity checks
#

# Make sure to given file exists
[[ -n "${inputFile}" ]] || btk_error "Updater has not provided the required file name"
[[ -e ${inputFile} ]]   || btk_error "Could not find ${inputFile}"

# Make sure required tools exists (helper calls btk_error on error, which exits)
btk_check_required_tools ${requiredTools}

# Get bank status
readonly bank1Status=$(fw_printenv bank1_status | sed 's:^.*=\(.*\)$:\1:')
readonly bank2Status=$(fw_printenv bank2_status | sed 's:^.*=\(.*\)$:\1:')

readonly currentKernelCrc16=$(fw_printenv kernel_crc16 | sed 's:^.*=\(.*\)$:\1:')
readonly currentRootfsCrc16=$(fw_printenv rootfs_crc16 | sed 's:^.*=\(.*\)$:\1:')

# Check if update is requiered
if [[ -e ${kernelCrc16File} ]] && [[ -e ${rootfsCrc16File} ]]
then
    readonly newPackageCrc16=$(<${packageCrc16File});
    #   Get new Kernel and Rootfs crc16
    readonly newKernelCrc16=$(<${kernelCrc16File});
    btk_print "New Kernel specified crc16: $newKernelCrc16"
    readonly newRootfsCrc16=$(<${rootfsCrc16File});
    btk_print "New RootFs specified crc16: $newRootfsCrc16"
else
    # New software crc16 files not found, do not update
    errorDetected=1;
    btk_error "New software crc16 files not found <${kernelCrc16File}> <${rootfsCrc16File}> , do not update"
fi

#   If Update is required, check both update file crc16 validity
if [ ${errorDetected} == 0 ]
then
    # If bank1 is blank or programmed, program it !
    if [[ "${bank1Status}" == "blank" ]] || [[ "${bank1Status}" == "programmed" ]]
    then
       btk_print "Bank #1 is ${bank1Status}, flash it"
       flash_bank 1
    # else if bank2 is blank or programmed, program it !
    elif [[ "${bank2Status}" == "blank"  ]] || [[ "${bank2Status}" == "programmed" ]]
    then
       btk_print "Bank #2 is ${bank2Status}, flash it"
       flash_bank 2
    # else exit
    else
       btk_error "No bank available for flashing: bank1 status [${bank1Status}] bank2 status [${bank2Status}]. Aborting"
    fi
fi

exit 0
