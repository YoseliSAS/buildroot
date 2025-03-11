#!/bin/bash

#
# Allow functions to pass it arguments
#
#

#------------------------------------------------------------------------------
# Allow expanding a range into a full list.
# Parameters:
#    A single string describing the range. The string can be made of a 
#     combination of single elements and ranges.
#    Ranges are reordered if needed so the end result is always growing.
# Example:
#   "1,5,6-9,13-12,21" expand as "1 5 6 7 8 9 12 13 21"
#------------------------------------------------------------------------------
function btk_arg_expand_range() {
   local singleOrRange all

   for singleOrRange in $(IFS=,; echo $1); do
      if [[ ${singleOrRange} == *-* ]]; then
         local pair=($(IFS=-; echo ${singleOrRange}))
         local -i start=${pair[0]} end=${pair[1]} temp
         
         ((start > end)) && ((temp=end, end=start, start=temp))
        
         for ((i=${start}; i<=${end}; ++i)); do
            all+="${all:+ }${i}"
         done
      else
         all+="${all:+ }${singleOrRange}"
      fi
   done

   echo ${all}
}

#------------------------------------------------------------------------------
# Create a expression to be evaluated to parse options and parameter for
#  a function or a main program.
# If a parameter is missing, or the input is incomplete, an error gets 
#  produced.
#
# Parameters:
#   A string describing the arguments must be supplied.
#   The string takes option using a short or long option. Default value can
#    be set using '='.
#   Parameters must be specified as last options. Default values can only be
#    specified for end options.
#   All other parameters are taken as the parameters to process.
#   For options taking values, it is possible to use --char='c' or --char c
#
# Echos:
#   A string to be evaluated. This string will set locally new variables
#   whose name match the option name, but prefixed with a '_'.
#   For example, the option -a would yield a _a variable, whilst an option
#    --args would yield _args.
#   For parameters, the same rule applies.
#   Any left over arguments are reinjected as $1, $2 etc..
#
# Example:
#   eval $(btk_args "--strip -c=3 var1 var2" $@)
#   would set:
#      _strip, _c, _var1 and _var2.
#------------------------------------------------------------------------------
function btk_args() {
   local arg flags lo
   local -a pos
   shopt -s extglob

   # Extract what's expected from the string. The last arg is the format string
   for arg in $(IFS=; echo "${1}"); do
      if [[ ${arg} == -* ]]; then
         flags+="${arg} "
      else
         # Always add a '='
         [[ ${arg} != *=+(?) ]] && arg+='='
         pos+=(${arg})
      fi
   done

   # Process the parameters
   local -i posIndex=0
   local -a leftOver=()
   shift

   while (($#>=1)); do
      arg=$1
      shift
      if [[ ${arg} == -* ]]; then
         # It's an option! Is it a known option?
         if [[ ${flags} == *${arg%=*}=* ]]; then
            # Value required. Either through an '=' or as the following arg
            if [[ ${arg} == *=* ]]; then
               value=${arg#*=}
               arg=${arg%=*}=
            else
               # Contained in the following arg which cannot be an option
               if [[ -n ${1} && ${1} != -* ]]; then
                  value=${1}
                  arg+="="
                  shift
               else
                  btk_error "Missing value for argument $arg"
               fi
            fi

            # Replace flag with flag=value
            flags=${flags/${arg}*([! ]) /${arg}${value} }
         elif [[ ${flags} == *${arg}\ * ]]; then
            # Simple flag - set as true
            flags=${flags/${arg}\ /${arg}=true }
         else
            # Not listed!
            btk_error "Argument ${arg} is not a valid argument to the function"
         fi
      else
         # Check our positionals
         if ((posIndex<${#pos[@]})); then
            # Assign to positional var
            pos[posIndex]=_${pos[posIndex]/=*/=${arg}}
            ((++posIndex))
         else
            # Append arg to left over
            leftOver+=(${arg})
         fi
      fi
   done

   # Any positional left un-assigned
   if ((posIndex<${#pos[@]})); then
      btk_error "Missing argument ${pos[index]}"
   fi

   # Set all undefined flags as false
   flags="${flags/= /=false }"

   # Convert dash and dashdash to _
   for arg in ${flags}; do
      pos+=(_${arg##+(-)})
   done

   echo -n "local ${pos[@]}"
   if ((${#leftOver[@]})); then
      echo "; set ${leftOver[@]}"
   else
      echo ""
   fi
}

#------------------------------------------------------------------------------
# Prints a split of the given string using the given separator
# Options:
#   -s Separator. Default is ':'
# Args:
#   The string to split
#   List of argument names to receive the pieces
# Example:
#   btk_arg_split -s=. hello.world hello world
#------------------------------------------------------------------------------
function btk_arg_split() {
   eval $(btk_args "-s=:" $@)
   echo "$(IFS=$_s; echo $1)"
}


