#!/bin/bash
#------------------------------------------------------------------------------
# Bash toolkit time helpers
#
# This file shall be sourced
#
# Authors: rsd
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# Get the uptime value in seconds
# STDOUT: the uptime value in seconds (integer)
#------------------------------------------------------------------------------
function btk_uptime_sec() {
   \cat /proc/uptime | \cut -f1 -d ' ' | \cut -f1 -d '.'
   return $?
}


#------------------------------------------------------------------------------
# Convert seconds to hh:mm:ss format
# STDOUT: the duration in hh:mm:ss format
#------------------------------------------------------------------------------
function btk_seconds_to_hms() {
   local _time_sec=$1
   local _hours=$(( _time_sec / 3600 ))
   local _minutes=$(( ( _time_sec % 3600 ) / 60 ))
   local _seconds=$(( _time_sec % 60 ))

   printf "%0.2d:%0.2d:%0.2d\n" ${_hours} ${_minutes} ${_seconds}
   return $?
}


#------------------------------------------------------------------------------
# Get the uptime value in hours:minutes:seconds format
# STDOUT: the uptime value in hours:minutes:seconds format
#------------------------------------------------------------------------------
function btk_uptime_hms() {

   btk_seconds_to_hms $(btk_uptime_sec)
   return $?
}


#------------------------------------------------------------------------------
# Get the duration in seconds since a time point in the past
# $1: timepoint in seconds
# STDOUT: the duration in seconds
#------------------------------------------------------------------------------
function btk_duration_sec_since() {

   echo $(( $(btk_uptime_sec) - $1 ))   
   return $?
}


#------------------------------------------------------------------------------
# Get the duration (hh:mm:ss format) since a time point in the past
# $1: timepoint in seconds
# STDOUT: the duration in hh:mm:ss format
#------------------------------------------------------------------------------
function btk_duration_hms_since() {

   btk_seconds_to_hms $(btk_duration_sec_since $1)
   return $?
}

