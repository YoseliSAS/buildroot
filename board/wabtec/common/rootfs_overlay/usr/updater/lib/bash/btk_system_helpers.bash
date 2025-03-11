#!/bin/bash
#------------------------------------------------------------------------------
# Bash toolkit system helpers
#
# This file shall be sourced
#
# Authors: rsd
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Get the used space of a path
# $1 : The path to be tested, can be a file or a directory
# $2 : The unit of the result: G =>gigabytes, M => Megabytes, k => Kilobytes, B => bytes.
#      By default: k
# STDOUT: the used space of the path
#
# Warning! In case size is a fraction of the block size, 'du' rounds to 1
#------------------------------------------------------------------------------
function btk_get_path_used_space() {
   local _fs_path
   (( $# > 0 )) && _fs_path=$1 || _fs_path="/"

   local _unit
   (( $# > 1 )) && _unit=$2 || _unit="k"

   # Convert unit in numerical value (to work with busybox df)
   local _block_size
   case ${_unit} in
      B) _block_size=1 ;;
      k) _block_size=1024 ;;
      M) _block_size=$((1024 * 1024)) ;;
      G) _block_size=$((1024 * 1024 * 1024)) ;;
      *) echo "invalid unit ${_unit}" >&2 ; return 1 ;;
   esac 

   \du ${_fs_path} -s -B ${_block_size} | cut -f1
   return $?
}


#------------------------------------------------------------------------------
# Get the free space available of a filesystem
# $1 : The filesystem to be tested
# $2 : The unit of the result: G =>gigabytes, M => Megabytes, k => Kilobytes, B => bytes.
#      By default: k
# STDOUT: the free space available in the filesystem
#------------------------------------------------------------------------------
function btk_get_fs_free_space() {
   
   local _fs_path
   (( $# > 0 )) && _fs_path=$1 || _fs_path="/"

   local _unit
   (( $# > 1 )) && _unit=$2 || _unit="k"

   # Convert unit in numerical value (to work with busybox df)
   local _block_size
   case ${_unit} in
      B) _block_size=1 ;;
      k) _block_size=1024 ;;
      M) _block_size=$((1024 * 1024)) ;;
      G) _block_size=$((1024 * 1024 * 1024)) ;;
      *) echo "invalid unit ${_unit}" >&2 ; return 1 ;;
   esac 

   \df ${_fs_path} -B ${_block_size} | tail -n +2 | tr -s ' ' | tr -d '\n' |  cut -f4 -d ' '
   return $?
}


#------------------------------------------------------------------------------
# Get the used space of a filesystem
# $1 : The filesystem to be tested
# $2 : The unit of the result: G =>gigabytes, M => Megabytes, k => Kilobytes, B => bytes.
#      By default: k
# STDOUT: the used space of the filesystem
#------------------------------------------------------------------------------
function btk_get_fs_used_space() {

   
   local _fs_path
   (( $# > 0 )) && _fs_path=$1 || _fs_path="/"

   local _unit
   (( $# > 1 )) && _unit=$2 || _unit="k"

   # Convert unit in numerical value (to work with busybox df)
   local _block_size
   case ${_unit} in
      B) _block_size=1 ;;
      k) _block_size=1024 ;;
      M) _block_size=$((1024 * 1024)) ;;
      G) _block_size=$((1024 * 1024 * 1024)) ;;
      *) echo "invalid unit ${_unit}" >&2 ; return 1 ;;
   esac 

   \df ${_fs_path} -B ${_block_size} | tail -n +2 | tr -s ' ' | tr -d '\n' |  cut -f3 -d ' '
   return $?
}


#------------------------------------------------------------------------------
# Get the capacity of a filesystem
# $1 : The filesystem to be tested
# $2 : The unit of the result: G =>gigabytes, M => Megabytes, k => Kilobytes, B => bytes.
#      By default: k
# STDOUT: the capacity of the filesystem
#------------------------------------------------------------------------------
function btk_get_fs_capacity() {

   local _fs_path
   (( $# > 0 )) && _fs_path=$1 || _fs_path="/"

   local _unit
   (( $# > 1 )) && _unit=$2 || _unit="k"

   # Convert unit in numerical value (to work with busybox df)
   local _block_size
   case ${_unit} in
      B) _block_size=1 ;;
      k) _block_size=1024 ;;
      M) _block_size=$((1024 * 1024)) ;;
      G) _block_size=$((1024 * 1024 * 1024)) ;;
      *) echo "invalid unit ${_unit}" >&2 ; return 1 ;;
   esac 

   \df ${_fs_path} -B ${_block_size} | tail -n +2 | tr -s ' ' | tr -d '\n' |  cut -f2 -d ' '
   return $?
}


#------------------------------------------------------------------------------
# Get the free space available of a filesystem
# $1 : The filesystem to be tested
# STDOUT: the free space available in the filesystem in Kilobytes
#------------------------------------------------------------------------------
function btk_get_fs_free_space_kb() {

   (( $# > 0 )) && btk_get_fs_free_space $1 k || btk_get_fs_free_space / k
   return $?
}


#------------------------------------------------------------------------------
# Get the used space of a filesystem
# $1 : The filesystem to be tested
# STDOUT: the used space of the filesystem in Kilobytes
#------------------------------------------------------------------------------
function btk_get_fs_used_space_kb() {

   (( $# > 0 )) && btk_get_fs_used_space $1 k || btk_get_fs_used_space / k
   return $?
}


#------------------------------------------------------------------------------
# Get the capacity of a filesystem
# $1 : The filesystem to be tested
# STDOUT: the capacity of the filesystem in Kilobytes
#------------------------------------------------------------------------------
function btk_get_fs_capacity_kb() {

   (( $# > 0 )) && btk_get_fs_capacity $1 k || btk_get_fs_capacity / k
   return $?
}


#------------------------------------------------------------------------------
# Get the free memory available (includes buffers and caches)
# $1 : The unit of the result: G =>gigabytes, M => Megabytes, k => Kilobytes, B => bytes.
#      By default: k
# STDOUT: the free space available (truncated)
#------------------------------------------------------------------------------
function btk_get_free_memory() {
   
   local _unit
   (( $# > 0 )) && _unit=$1 || _unit="k"

   # Free memory includes buffers and the amount of cached memory
   local let _free_memory_kb=$(cat /proc/meminfo | grep "MemFree:" | tr -s ' ' | cut -f2 -d ' ') 
   local let _buffers_memory_kb=$(cat /proc/meminfo | grep "Buffers:" | tr -s ' ' | cut -f2 -d ' ') 
   local let _cached_memory_kb=$(cat /proc/meminfo | grep "^Cached:" | tr -s ' ' | cut -f2 -d ' ')
   _free_memory_kb=$(( ${_free_memory_kb} + ${_buffers_memory_kb} + ${_cached_memory_kb} ))

   # Do the unit conversion
   case ${_unit} in
      B) echo $(( ${_free_memory_kb} * 1024 )) ;;
      k) echo ${_free_memory_kb} ;;
      M) echo $(( ${_free_memory_kb} / 1024 )) ;;
      G) echo $(( ${_free_memory_kb} / ( 1024 * 1024 ) )) ;;
      *) echo "invalid unit ${_unit}" >&2 ; return 1 ;;
   esac 

   return 0
}


#------------------------------------------------------------------------------
# Get the used memory
# $1 : The unit of the result: G =>gigabytes, M => Megabytes, k => Kilobytes, B => bytes.
#      By default: k.
# STDOUT: the used memory (truncated)
#------------------------------------------------------------------------------
function btk_get_used_memory() {

   local _unit
   (( $# > 0 )) && _unit=$1 || _unit="k"

   # Used memory is equal to the capacity less the free memory
   # Do calculation in Bytes in order to be more precise
   local let _used_memory_bytes=$(( $(btk_get_memory_capacity B ) - $(btk_get_free_memory B ) ))
   [[ $? != 0 ]] && return $?

   # Do the unit conversion
   case ${_unit} in
      B) echo ${_used_memory_bytes} ;;
      k) echo $(( ${_used_memory_bytes} / 1024 )) ;;
      M) echo $(( ${_used_memory_bytes} / ( 1024 * 1024 ) )) ;;
      G) echo $(( ${_used_memory_bytes} / ( 1024 * 1024 * 1024 ) )) ;;
      *) echo "invalid unit ${_unit}" >&2 ; return 1 ;;
   esac

   return 0
}


#------------------------------------------------------------------------------
# Get the memory capacity
# $1 : The unit of the result: G =>gigabytes, M => Megabytes, k => Kilobytes, B => bytes.
#      By default: k
# STDOUT: the memory capacity (truncated)
#------------------------------------------------------------------------------
function btk_get_memory_capacity() {

   local _unit
   (( $# > 0 )) && _unit=$1 || _unit="k"

   local let _memory_capacity_kb=$(cat /proc/meminfo | grep "MemTotal:" | tr -s ' ' | cut -f2 -d ' ') 
   [[ $? != 0 ]] && return $?

   # Do the unit conversion
   case ${_unit} in
      B) echo $(( ${_memory_capacity_kb} * 1024 )) ;;
      k) echo ${_memory_capacity_kb} ;;
      M) echo $(( ${_memory_capacity_kb} / 1024 )) ;;
      G) echo $(( ${_memory_capacity_kb} / ( 1024 * 1024 ) )) ;;
      *) echo "invalid unit ${_unit}" >&2 ; return 1 ;;
   esac 

   return 0
}


#------------------------------------------------------------------------------
# Get the memory used by a process
# $1 : The pid of the process to be analysed
# $2 : The unit of the result: G =>gigabytes, M => Megabytes, k => Kilobytes, B => bytes.
#      By default: k
# STDOUT: the memory used by the process (truncated)
#------------------------------------------------------------------------------
function btk_get_process_memory() {

   local _pid=$1

   # Sanity checks
   (( $# >= 1 )) || { echo "no PID provided" >&2 ; return 1 ; }
   kill -0 ${_pid} 2>&1 >/dev/null || { echo "PID $1 is invalid" >&2 ; return 1 ; }

   local _unit
   (( $# > 1 )) && _unit=$2 || _unit="k"
   
   # cut / tr combo is prefered to awk use because this way is more efficient
   local let _proces_memory_kb=$(( $( cat /proc/${_pid}/smaps \
      | grep Refere | tr -s  ' ' | cut -f2 -d ' ' | xargs | tr ' ' '+' ) ))
   [[ $? != 0 ]] && return $?

   # Do the unit conversion
   case ${_unit} in
      B) echo $(( ${_proces_memory_kb} * 1024 )) ;;
      k) echo ${_proces_memory_kb} ;;
      M) echo $(( ${_proces_memory_kb} / 1024 )) ;;
      G) echo $(( ${_proces_memory_kb} / ( 1024 * 1024 ) )) ;;
      *) echo "invalid unit ${_unit}" >&2 ; return 1 ;;
   esac 

   return 0
}


#------------------------------------------------------------------------------
# Lock a file lock
# The lock mecanism is based on the mkdir command: 
# The directory creation is atomic on Linux platforms
# $1 : The lock file name (not a path)
#------------------------------------------------------------------------------
function btk_lock(){
   local _lock_file=/tmp/btk_lock/$1
   local _lock_pid_file=${_lock_file}/pid
   mkdir -p $(dirname ${_lock_file})

   while true ; do

      # The directory creation by using mkdir is atomic on Linux/BSD platforms
      # =>  Use the directory as lock file. try to create it with mkdir and check the result.
      while ! mkdir ${_lock_file} 2>/dev/null ; do
         # Cannot create the directory 
         # => Another process has created the directory and thus holds the lock
         # Wait for the lock releasing (removing of the directory)
         sleep 0.2
      done
      
      # There is sometimes some lock issue (take a lock owned by someone). 
      # Make more robust the lock by checking the PID file.
      # A race condition could still occur but the occurence is really decreased.
      
      # PID file is not present: lock is not hold by someone else
      [[ ! -f "${_lock_pid_file}" ]] && break

   done
   
   # We got the lock: keep a trace of the owner
   # This is just for sanity checks.
   echo $$ > ${_lock_pid_file}
   
   return 0
}


#------------------------------------------------------------------------------
# Unlock a lock with btk_lock
# $1 : The lock file name (not a path)
#------------------------------------------------------------------------------
function btk_unlock(){
   local _lock_file=/tmp/btk_lock/$1

   # Sanity checks before unlocking the lock.

   # Check if the lock exists
   if [[ ! -d "${_lock_file}" ]] ; then
      btk_print "Tried to unlock a file lock ${_lock_file} not hold by someone"
      return 1
   fi

   # Try to check if we are the owner of the lock
   local _owner_pid=$(cat ${_lock_file}/pid 2>/dev/null)
   if [[ -n "${_owner_pid}" ]] && [[ "${_owner_pid}" != "$$" ]] ; then
      btk_print "Tried to unlock a file lock ${_lock_file} hold by another process (${_owner_pid})"
      return 1
   fi

   # Remove lock
   if [[ -d "${_lock_file}" ]] ; then
      rm -rf ${_lock_file}/*
      # Remove the directory: it will unlock pending process
      rmdir ${_lock_file}
   fi
      
   return 0
}


#------------------------------------------------------------------------------
# Unlock a lock with btk_lock. No check is done
# $1 : The lock file name (not a path)
#------------------------------------------------------------------------------
function btk_unlock_no_check(){
   local _lock_file=/tmp/btk_lock/$1

   # Remove lock
   if [[ -d "${_lock_file}" ]] ; then
      rm -rf ${_lock_file}/*
      # Remove the directory: it will unlock pending process
      rmdir ${_lock_file}
   fi

   return 0
}


#------------------------------------------------------------------------------
# Force a hard reboot on the local machine 
# (Immediately reboot the system, without unmounting or syncing filesystems)
# $?: 1 if the command failed
#------------------------------------------------------------------------------
function btk_force_hard_reboot(){

   if [[ -e /proc/sys/kernel/sysrq ]] ; then
      # Activate Magic SysRq
      echo 1 > /proc/sys/kernel/sysrq

      # And perform the hard boot request
      [[ -e /proc/sysrq-trigger ]] && echo b > /proc/sysrq-trigger
   fi

   # If we arrive here: the command is not available
   return 1
}


#------------------------------------------------------------------------------
# Force a shutdown on the local machine
# $?: 1 if the command failed
#------------------------------------------------------------------------------
function btk_force_shutdown(){

   if [[ -e /proc/sys/kernel/sysrq ]] ; then
      # Activate Magic SysRq
      echo 1 > /proc/sys/kernel/sysrq

      # And perform the shutdown request
      [[ -e /proc/sysrq-trigger ]] && echo o > /proc/sysrq-trigger
   fi

   # If we arrive here: the command is not available
   return 1
}


#------------------------------------------------------------------------------
# Check required tools are available
# $@: The list of tools to check
# STDOUT: prints the missing tools
# $?: 1 if a tool is missing
#------------------------------------------------------------------------------
function btk_check_required_tools(){
   local _ret=0
   local _missing_tools=""

   for tool in $@ ; do
      if ! which ${tool} > /dev/null ; then
         _missing_tools="${_missing_tools} ${tool}"
         btk_print "${tool} is not installed on system"
         _ret=1
      fi
   done

   if [[ "${_ret}" != "0" ]] ; then
       btk_error "Missing the following required tools [${_missing_tools}], exiting..."
   fi

   return ${_ret}
}


#------------------------------------------------------------------------------
# Flash an MTD device with a file
# $1: The file to flash
# $2: The MTD device (/dev/mtdx)
# $3: expected CRC
# $4: Block size (optional), used for dd (default: 131072)
# STDOUT: prints the error
# $?: 1 if an error occured
#------------------------------------------------------------------------------
function btk_flash_mtd_device(){

   declare -i  _ret=0
   declare -i  _block_size=131072

   # Check input parameters
   (( $# >= 3 )) || btk_error "At least 3 arguments required : file, mtd device and expected crc"

   # Get input parameters
   declare -r  _file=$1
   declare -r  _mtd=$2
   declare -r  _expected_crc=${3}
   declare -i  _nb_blocks=0
   declare     _flash_crc=
   
   # Get optional block size
   (( $# > 3 )) && _block_size=$4

   # Check mtd device
   if [[ ! -e "${_mtd}" ]] ; then
      btk_print "Error: Missing ${_mtd}"
      return 1
   fi

   # Get size of file
   _file_size=$(stat -c %s ${_file})
   if test -z ${_file_size} ; then
      btk_print "${_file} has size ${_file_size}, nothing to do"
      return ${_ret}
   fi

   # Calculate the number of blocks to erase
   readonly _nb_blocks=$(( ${_file_size} / ${_block_size} ))

   # Copy to flash
   btk_print "nandwrite -q -p -m ${_mtd} ${_file}"
   flash_erase -q ${_mtd} 0 0
   nandwrite -q -p -m ${_mtd} ${_file}
   btk_print "nandwrite done"

   # verify crc of writtent data
   btk_print "Verifying Flash content :"
   btk_print "  Expected CRC is : ${_expected_crc}"
   btk_print "  Getting Flash CRC..."
   _flash_crc=$(nanddump -q --bb=skipbad --length=${_file_size} ${_mtd} | ${crc16Processor} -s ${_file_size})
   btk_print "  Flash CRC = ${_flash_crc}"

   # compare CRCs (double comma means conversion to lower case)
   if [[ "${_expected_crc,,}" == "${_flash_crc,,}" ]]
   then
      btk_print "  CRC is correct"
   else
      btk_print "  Error: wrong CRC"
      _ret=2
   fi

   return ${_ret}
}

#------------------------------------------------------------------------------
# Flash an MTD device with a file
# $1: The MTD device (/dev/mtdx)
# $2: The MTD device size
# $3: Block size (optional), used for dd (default: 131072)
# STDOUT: prints the error
# $?: 1 if an error occured
#------------------------------------------------------------------------------
function btk_erase_mtd_device(){

   local _ret=0
   local _block_size=131072

   # Check input parameters
   (( $# >= 2 )) || btk_error "At least 2 arguments required, mtd device and mtd size"

   # Get input parameters
   local _mtd=$1
   local _mtd_size=$2

   # Get optional block size
   (( $# > 2 )) && _block_size=$3

   # Check mtd device
   if [[ ! -e "${_mtd}" ]] ; then
      btk_print "Error: Missing ${_mtd}"
      return 1
   fi

   # Get size of file
   if test -z ${_mtd_size} ; then
      btk_print "${_mtd} has size ${_mtd_size}, nothing to do"
      return ${_ret}
   fi

   # Calculate the number of blocks to erase
   _nb_blocks=$(( ${_mtd_size} / ${_block_size} ))

   # Erase mtd block
   btk_print "Erasing ${_mtd}... => dd if=/dev/zero of=${_mtd} bs=${_block_size} count=${_nb_blocks}"
   if dd if=/dev/zero of=${_mtd} bs=${_block_size} count=${_nb_blocks} oflag=direct; then
      btk_print "Erase OK"
   else
      btk_print "Erase failed"
      return 1
   fi

   return ${_ret}
}
