#!/bin/bash
#------------------------------------------------------------------------------
# Bash toolkit file helpers
#
# This file shall be sourced
#
# Authors: rsd
#------------------------------------------------------------------------------

btk_import print_helpers

#------------------------------------------------------------------------------
# Tests if a file exists in PATH
# $1 : The name of the file to be tested
# $? : 0 if found, 1 otherwise
#------------------------------------------------------------------------------
function btk_exists_in_path() {
   local _file_exists

   local -r _test_file="$1"

   # Save current values
   local -r _ifs_backup=${IFS}

   # parse each individual absolute path in the PATH
   IFS=$':'
   for i in ${PATH}
   do
      # find the file in the directory $i
      if [ -e "$i/${_test_file}" ]; then
         _file_exists=0
         break
      else
         _file_exists=1
      fi
   done

   # Restore values
   IFS=${_ifs_backup}

   return ${_file_exists}
}

#------------------------------------------------------------------------------
# Computes the checksum of any file and print it to stdout
# $1 : The file
# OUT: stdout
#------------------------------------------------------------------------------
function btk_cksum() {
   echo $(\cksum $1 | awk '{print $1}')
   return $?
}

#------------------------------------------------------------------------------
# Return the absolute path of a file that exists
# $1 : The file
# OUT: stdout
#------------------------------------------------------------------------------
btk_absolute_path() {
    local _parent_dir=$(dirname "$1")
    echo "$( cd -P ${_parent_dir} ; pwd)/$(basename $1)"
    return $?
}

#------------------------------------------------------------------------------
# Return the absolute path of the current script.
# OUT: stdout
#------------------------------------------------------------------------------
function btk_this_script_path() {
   btk_absolute_path "$0"
   return $?
}

#------------------------------------------------------------------------------
# Test if an executable exists (test its path and if present in PATH)
# $1 : The name or path of the file to be tested
# $? : 0 if found, 1 otherwise
#------------------------------------------------------------------------------
function btk_exec_exists() {
   local _exec_path="$1"
   local _cr=1

   # Test the path of the file
   [[ -x "${_exec_path}" ]] && return 0

   # Search in PATH.
   # "which" can return a not executable file if it is located in local directory
   _exec_path=$(which "${_exec_path}" | head -n 1)
   if [[ $? -eq 0 ]] && [[ -x "${_exec_path}" ]] ; then
      _cr=0
   else
       # Not found
      _cr=1
   fi

   return ${_cr}
}

#------------------------------------------------------------------------------
# Source a file. Manage errors
# $1 : The name or path of the file to be sourced
#------------------------------------------------------------------------------
function btk_source() {
   local -r _file_to_be_sourced="$1"
   local _cr=0

   trap 'btk_error "Error in the sourced file: ${_file_to_be_sourced}"' ERR
   source ${_file_to_be_sourced}
   _cr=$?
   trap - ERR # Reset the error trap

   return ${_cr}
}

#------------------------------------------------------------------------------
# Source a file if exists. Manage errors
# $1 : The name or path of the file to be sourced
#------------------------------------------------------------------------------
function btk_source_optional() {
   local -r _file_to_be_sourced=$1
   local _cr=0

   if [[ -f "${_file_to_be_sourced}" ]] ; then
      btk_source "${_file_to_be_sourced}"
      _cr=$?
   elif btk_exists_in_path "${_file_to_be_sourced}" ; then
      btk_source "${_file_to_be_sourced}"
      _cr=$?
   fi

   return ${_cr}
}

#------------------------------------------------------------------------------
# Get the size of any file and print it to stdout
# $1 : The file
# OUT: stdout
#------------------------------------------------------------------------------
function btk_file_size() {
   local -r _input_file=$1

   # Sanity checks
   [[ -f "${_input_file}" ]] || return 1

   # Use "stat -c" in order to be compliant with the busybox stat command
   \stat -c "%s" "${_input_file}"

   return $?
}

#------------------------------------------------------------------------------
# Set owner/group and access rights for a given file
# $1 : The file
# $2 : Access rights as octal value
# $3 : Owner/Group as string
# OUT: stdout
#------------------------------------------------------------------------------
function btk_chmod_chown() {
   local -r _input_file=$1
   local -r _input_mode=$2
   local -r _input_ownergroup=$3

   # Sanity checks
   [[ -e "${_input_file}" ]] || return 1
   #echo "btk_chmod_chown for <${_input_file}> with <${_input_mode}> and <${_input_ownergroup}>"
   chmod "${_input_mode}" "${_input_file}"
   chown "${_input_ownergroup}" "${_input_file}"

   return $?
}
