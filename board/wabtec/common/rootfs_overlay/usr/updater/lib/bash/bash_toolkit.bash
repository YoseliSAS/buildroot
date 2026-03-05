#!/bin/bash
#------------------------------------------------------------------------------
# Bash toolkit header
#
# This file shall be sourced
#
# Authors: rsd
#------------------------------------------------------------------------------

[[ -z "${BASH_TOOLKIT_SOURCED}" ]] || return 0
readonly BASH_TOOLKIT_SOURCED="y"

#------------------------------------------------------------------------------
# Return a canonical path to this file.
# The function works inside sourced or executed files.
# Echos:
#   The path to the file
#------------------------------------------------------------------------------
function btk_this_path() {
   local _dir="../bash"

   # Special case when running inside bashdb
   if [[ $BASH_SOURCE != "$$BASH_SOURCE" ]]; then
      local _source="${BASH_SOURCE[0]}"

      # Go through all symlinks to find the ultimate location of the source file
      while [ -h "$_source" ] ; do
         _source="$(readlink "$_source")";
      done

      # Get an absolute path to the directory that contains this file
      _dir="$( cd -P "$( dirname "$_source" )" && pwd )"
   fi

   echo "${_dir}"
}

#------------------------------------------------------------------------------
# Source a toolkit file as a module. The module is only sourced once.
# This function takes care of the path and of the extension
# Parameters:
#   Name of the btk service to source. btk_ prefix and .bash suffix are
#    optional.
#------------------------------------------------------------------------------
function btk_import() {
   local _btk_source_no_prefix=${1#btk_}
   local _btk_source_lib=${_btk_source_no_prefix%.bash}
   local _btk_source_marker=BTK_${_btk_source_lib^^}_SOURCED

   if [[ -z "${!_btk_source_marker}" ]]; then
      source $(btk_this_path)/btk_${_btk_source_lib}.bash
      eval readonly ${_btk_source_marker}='true'
   fi
}

# Source all libs by default
btk_import print_helpers
btk_import file_helpers
btk_import network_helpers
btk_import system_helpers
btk_import time_helpers
btk_import args
btk_import sound
btk_import IO
