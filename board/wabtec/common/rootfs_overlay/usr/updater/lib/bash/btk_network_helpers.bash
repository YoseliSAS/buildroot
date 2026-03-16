#!/bin/bash
#------------------------------------------------------------------------------
# Bash toolkit network helpers
#
# This file shall be sourced
#
# Authors: rsd
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Get the IP address of a network interface
# $1 : The name of the network interface
# OUT: stdout
#------------------------------------------------------------------------------
function btk_get_ip_addr() {

   local net_itf
   local ret=1

   if [[ $# -gt 0 ]] ; then
      net_itf=$1

      /sbin/ifconfig "${net_itf}" | \grep '\<inet\>' \
         | \sed -n '1p' | \tr -s ' ' | \cut -d ' ' -f3 | \cut -d ':' -f2
      ret=$?
   fi

   return ${ret}
}

#------------------------------------------------------------------------------
# Get the subnet mask of a network interface
# $1 : The name of the network interface
# OUT: stdout
#------------------------------------------------------------------------------
function btk_get_subnet_mask() {

   local net_itf
   local ret=1

   if [[ $# -gt 0 ]] ; then
      net_itf=$1

      # Loopback device has not broadcast field
      if [[ "${net_itf}" != "lo" ]] ; then
         /sbin/ifconfig "${net_itf}" | \grep '\<inet\>' \
            | \sed -n '1p' | tr -s ' ' | \cut -d ' ' -f5 | \cut -d ':' -f2
         ret=$?
      else
         /sbin/ifconfig "${net_itf}" | \grep '\<inet\>' \
            | \sed -n '1p' | \tr -s ' ' | \cut -d ' ' -f4 | \cut -d ':' -f2
         ret=$?
      fi
   fi

   return ${ret}
}

#------------------------------------------------------------------------------
# Get the subnet broadcast address of a network interface
# $1 : The name of the network interface
# OUT: stdout
#------------------------------------------------------------------------------
function btk_get_subnet_broadcast() {

   local net_itf
   local ret=1

   if [[ $# -gt 0 ]] ; then
      net_itf=$1

      # Loopback device has not broadcast field
      if [[ "${net_itf}" == "lo" ]] ; then
         echo ""
         ret=$?
      else
         /sbin/ifconfig "${net_itf}" | \grep '\<inet\>' \
            | \sed -n '1p' | \tr -s ' ' | \cut -d ' ' -f4 | \cut -d ':' -f2
         ret=$?
      fi
   fi

   return ${ret}
}

#------------------------------------------------------------------------------
# Get the MAC address of a network interface
# $1 : The name of the network interface
# OUT: stdout
#------------------------------------------------------------------------------
function btk_get_mac_addr() {

   local net_itf
   local ret=1

   if [[ $# -gt 0 ]] ; then
      net_itf=$1

      /sbin/ifconfig ${net_itf} | \grep "${net_itf}" | \tr -s ' ' | \cut -d ' ' -f5
      ret=$?
   fi

   return ${ret}
}

#------------------------------------------------------------------------------
# Get the list of the network interface
# OUT: stdout
#------------------------------------------------------------------------------
function btk_get_net_itf_list() {
   local ret=1

   /sbin/ifconfig -a | \grep "Link" | \tr -s ' ' | \cut -f1 -d ' ' | \xargs
   ret=$?

   return ${ret}
}

#------------------------------------------------------------------------------
# Test if a network interface exists
# $1 : The name of the network interface to be tested
# $? : 0 if found, 1 otherwise
#------------------------------------------------------------------------------
function btk_net_itf_exists() {
   local net_itf=$1
   local ret=1

   /sbin/ifconfig ${net_itf} 1>/dev/null 2>/dev/null
   ret=$?

   return ${ret}
}

#------------------------------------------------------------------------------
# Test if a network interface is up
# $1 : The name of the network interface to be tested
# $? : 0 if found, 1 otherwise
#------------------------------------------------------------------------------
function btk_net_itf_is_up() {
   local net_itf=$1

   # If interface doesn't exist the returned value is the same as if the interface wasn't up
   local ret=1
   if btk_net_itf_exists ${net_itf}; then
      /sbin/ifconfig ${net_itf}  2>/dev/null | grep "UP" 1>/dev/null 2>/dev/null
      ret=$?
   fi

   return ${ret}
}

#------------------------------------------------------------------------------
# Test if a network interface has got ip
# $1 : The name of the network interface to be tested
# $? : 0 if found, 1 otherwise
#------------------------------------------------------------------------------
function btk_net_itf_has_got_ip() {
   local net_itf=$1

   local ret=1
   if btk_net_itf_is_up ${net_itf}; then
      ip=$(btk_get_ip_addr ${net_itf})
      ret=$?
      if [[ ${ret} -eq 0 && -n "${ip}" ]] ; then
         ret=0
      else
         ret=1
      fi
   fi

   return ${ret}
}

#------------------------------------------------------------------------------
# Convert a numeric IPv4 address to an ASCII IPv4 address
# $1 : The numeric IPv4 address to be converted
# stdout: The converted ASCII IPv4 address (dotted decimal notation: x.x.x.x )
#------------------------------------------------------------------------------
function btk_ip4_itoa() {
   # Returns the dotted-decimal ascii form of an IP arg passed in integer format
   echo -n "$(($(($(($((${1}/256))/256))/256))%256))."
   echo -n "$(($(($((${1}/256))/256))%256))."
   echo -n "$(($((${1}/256))%256))."
   echo "$((${1}%256))"
}

#------------------------------------------------------------------------------
# Convert an ASCII IPv4 address to a numeric IPv4 address
# $1 : The ASCII IPv4 address to be converted (dotted decimal notation: x.x.x.x )
# stdout: The converted numeric IPv4 address
#------------------------------------------------------------------------------
function btk_ip4_atoi() {
   # Returns the integer representation of an IP arg, passed in ascii dotted-decimal notation (x.x.x.x)
   local _ip_addr=$1
   local _ip_num=0
   for (( _part=0 ; _part<4 ; ++_part )); do
      (( _ip_num+=${_ip_addr%%.*} * $((256**$((3-${_part}))))))
      _ip_addr=${_ip_addr#*.}
   done
   echo ${_ip_num}
}
