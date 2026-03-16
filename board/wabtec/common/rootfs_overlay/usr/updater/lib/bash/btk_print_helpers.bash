#!/bin/bash
#------------------------------------------------------------------------------
# Bash toolkit print helpers
#
# This file shall be sourced
#
# Environment variables that can be defined:
# BTK_LOG_OUTPUT             : redirect logs this another optional file
# BTK_ON_ERROR_HOOK          : hook called on error (before exiting script)
# BTK_SYSLOG_OUTPUT_DISABLED : if set to "y" disable the syslog output for btk_print and btk_error
#
# Authors: rsd
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Print function. Keep a trace in Syslog and a file.
# Save the output in an output file if the BTK_LOG_OUTPUT variable is defined
# $1 : The string to be logged. Optional parameter can be passed to the lower layout
# (if starts by a '-' character)
#------------------------------------------------------------------------------
function btk_print() {
   local arg=$1
   local opt
   while [[ ${arg:0:1} == '-' ]]; do
      opt="${opt:+${opt} }"$1
      shift
      arg=$1
   done
   [[ "${BTK_SYSLOG_OUTPUT_DISABLED}" == "y" ]] || logger -t $(basename "$0") "$@"
   if [[ -n "${BTK_LOG_OUTPUT}" ]] ; then
      echo ${opt} "$@" | tee -a ${BTK_LOG_OUTPUT}
   else
      echo ${opt} "$@"
   fi
}

#------------------------------------------------------------------------------
# Error function. Print and exit
# Save the output in an output file if the BTK_LOG_OUTPUT variable is defined
# The BTK_ON_ERROR_HOOK variable is used to call some process on error
# $1 : The string to be logged
#------------------------------------------------------------------------------
function btk_error() {
   btk_print "ERROR: $@ ($(caller))" 1>&2

   # Call the hook before exiting
   ${BTK_ON_ERROR_HOOK}

   trap - ERR
   exit 1
}

#------------------------------------------------------------------------------
# Print function supporting indent. Keep a trace in Syslog and a file.
# Save the output in an output file if the BTK_LOG_OUTPUT variable is defined
# $1 : The indent level (3 spaces by level). allowed values: 0..N levels
# $2 : The string to be logged
#------------------------------------------------------------------------------
function btk_print_with_indent() {
   local -i indent=$1
   shift
   btk_print "$(printf '%'$((indent*3))'s')$@"
}
