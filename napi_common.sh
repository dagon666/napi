#!/bin/bash

# force indendation settings
# vim: ts=4 shiftwidth=4 expandtab

#
# version for the whole bundle (napi.sh & subotage.sh)
#
declare -r g_revision="v1.3.6"

########################################################################
########################################################################
########################################################################

#  Copyright (C) 2014 Tomasz Wisniewski aka 
#       DAGON <tomasz.wisni3wski@gmail.com>
#
#  http://github.com/dagon666
#  http://pcarduino.blogspot.co.ul
# 
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

########################################################################
########################################################################
########################################################################


################################## GLOBALS #####################################

declare -r ___VERBOSITY=0
declare -r ___LOG=1
declare -r ___FORK=2
declare -r ___CNT=3
declare -r ___LOG_OWR=4

#
# 0 - verbosity
# - 0 - be quiet (prints only errors)
# - 1 - standard level (prints errors, warnings, statuses & msg)
# - 2 - info level (prints errors, warnings, statuses, msg & info's)
# - 3 - debug level (prints errors, warnings, statuses, msg, info's and debugs)
#
# 1 - the name of the file containing the output
#
# 2 - fork id
# 3 - msg counter
# 4 - flag defining whether to overwrite the log or not
#
declare -a g_output=( 1 'none' 0 1 0 )

################################## RETVAL ######################################

# success
declare -r RET_OK=0

# function failed
declare -r RET_FAIL=255

# parameter error
declare -r RET_PARAM=254

# parameter/result will cause the script to break
declare -r RET_BREAK=253

# resource unavailable
declare -r RET_UNAV=252

# no action taken
declare -r RET_NOACT=251

################################################################################

#
# @brief count the number of lines in a file
#
count_lines() {

    # it is being executed in a subshell to strip any leading white spaces
    # which some of the wc versions produce

    # shellcheck disable=SC2046
    # shellcheck disable=SC2005
    echo $(wc -l)
}


#
# @brief lowercase the input
#
lcase() {
    # some old busybox implementations have problems with locales
    # which renders that syntax unusable
    # tr '[:upper:]' '[:lower:]'

    # deliberately reverted to old syntax
    # shellcheck disable=SC2021
    tr '[A-Z]' '[a-z]'
}


#
# @brief get rid of the newline/carriage return
#
strip_newline() {
    tr -d '\r\n'
}


#
# @brief get the extension of the input
#
get_ext() {
    echo "${1##*.}"
}


#
# @brief strip the extension of the input
#
strip_ext() {
    echo "${1%.*}"
}


#
# @brief get the value from strings like key=value
#
get_value() {
    echo "${1##*=}"
}


#
# @brief get the key from strings like key=value
#
get_key() {
    echo "${1%=*}"
}


#
# @brief search for specified key and return it's value
# @param key
# @param array
#
lookup_value() {
    local i=''
    local rv=$RET_FAIL
    local key="$1" && shift
    local tk=''

    # using $* is deliberate to allow parsing either array or space delimited strings

    # shellcheck disable=SC2048
    for i in $*; do
        tk=$(get_key "$i")
        if [ "$tk"  = "$key" ]; then
            get_value "$i"
            rv=$RET_OK
            break
        fi
    done
    return $rv
}


#
# @brief lookup index in the array for given value
# returns the index of the value and 0 on success
#
lookup_key() {
    local i=''
    local idx=0
    local rv=$RET_FAIL
    local key="$1" 

    shift

    for i in "$@"; do
        [ "$i" = "$key" ] && rv=$RET_OK && break
        idx=$(( idx + 1 ))
    done

    echo $idx
    return $rv
}


#
# @brief modify value in the array (it will be added if the key doesn't exist)
# @param key
# @param value
# @param array
#
modify_value() {
    local key=$1 && shift
    local value=$1 && shift
    
    local i=0
    local k=''
    declare -a rv=()

    # shellcheck disable=SC2048
    for i in $*; do
        k=$(get_key "$i")
        # unfortunately old shells don't support rv+=( "$i" )
        [ "$k" != "$key" ] && rv=( "${rv[@]}" "$i" )
    done

    rv=( "${rv[@]}" "$key=$value" )
    echo ${rv[*]}

    return $RET_OK
}


#
# determines number of available cpu's in the system
#
get_cores() {
    local os="${1:-linux}"
    
    if [ "$os" = "darwin" ]; then
        sysctl hw.ncpu | cut -d ' ' -f 2
	else
        grep -i processor /proc/cpuinfo | wc -l
    fi
}



#
# @brief detects running system type
#
get_system() {
    uname | lcase
}


#
# @brief extracts http status from the http headers
#
get_http_status() {
    # grep -o "HTTP/[\.0-9]* [0-9]*"
    awk '{ m = match($0, /HTTP\/[\.0-9]* [0-9]*/); if (m) print substr($0, m, RLENGTH) }'
}

################################## STDOUT ######################################

#
# @brief produce output
#
_blit() {
    printf "#%02d:%04d %s\n" ${g_output[$___FORK]} ${g_output[$___CNT]} "$*"
    g_output[$___CNT]=$(( g_output[$___CNT] + 1 ))
}


#
# @brief set insane verbosity
#
_debug_insane() {
    PS4='+ [${LINENO}] ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    set -x
}


#
# @brief print a debug verbose information
#
_debug() {
    local line="${1:-0}" && shift
    [ "${g_output[$___VERBOSITY]}" -ge 3 ] && _blit "--- $line: $*"
    return $RET_OK
}


#
# @brief print information 
#
_info() {
    local line=${1:-0} && shift
    [ "${g_output[$___VERBOSITY]}" -ge 2 ] && _blit "-- $line: $*"
    return $RET_OK
}


#
# @brief print warning 
#
_warning() {
    _status "WARNING" "$*"
    return $RET_OK
}


#
# @brief print error message
#
_error() {
    local tmp="${g_output[$___VERBOSITY]}"
    g_output[$___VERBOSITY]=1
    _status "ERROR" "$*" | to_stderr
    g_output[$___VERBOSITY]="$tmp"
    return $RET_OK
}


#
# @brief print standard message
#
_msg() {
    [ "${g_output[$___VERBOSITY]}" -ge 1 ] && _blit "- $*"
    return $RET_OK
}


#
# @brief print status type message
#
_status() {
    [ "${g_output[$___VERBOSITY]}" -ge 1 ] && _blit "$1 -> $2"
    return $RET_OK
}


#
# @brief redirect errors to standard error output
#
to_stderr() {
    if [ -n "${g_output[$___LOG]}" ] && [ "${g_output[$___LOG]}" != "none" ]; then
        cat
    else
        cat > /dev/stderr
    fi
}


#
# @brief redirect stdout to logfile
#
redirect_to_logfile() {
    if [ -n "${g_output[$___LOG]}" ] && [ "${g_output[$___LOG]}" != "none" ]; then
        # truncate
        cat /dev/null > "${g_output[$___LOG]}"
        
        # append instead of ">" to assure that children won't mangle the output
        exec 3>&1 4>&2 1>> "${g_output[$___LOG]}" 2>&1 
    fi
}


#
# @brief redirect output to stdout
#
redirect_to_stdout() {
    # restore everything
    [ -n "${g_output[$___LOG]}" ] && 
    [ "${g_output[$___LOG]}" != "none" ] && 
        exec 1>&3 2>&4 4>&- 3>&- 
}

# EOF

################################## FLOAT CMP ###################################

float_lt() {
    awk -v n1="$1" -v n2="$2" 'BEGIN{ if (n1<n2) exit 0; exit 1}'
}


float_gt() {
    awk -v n1="$1" -v n2="$2" 'BEGIN{ if (n1>n2) exit 0; exit 1}'
}


float_le() {
    awk -v n1="$1" -v n2="$2" 'BEGIN{ if (n1<=n2) exit 0; exit 1}'
}


float_ge() {
    awk -v n1="$1" -v n2="$2" 'BEGIN{ if (n1>=n2) exit 0; exit 1}'
}


float_eq() {
    awk -v n1="$1" -v n2="$2" 'BEGIN{ if (n1==n2) exit 0; exit 1}'
}

float_div() {
    awk -v n1="$1" -v n2="$2" 'BEGIN { print n1/n2 }'
}

float_mul() {
    awk -v n1="$1" -v n2="$2" 'BEGIN { print n1*n2 }'
}

#################################### ENV #######################################

#
# @brief checks if the tool is available in the PATH
#
verify_tool_presence() {
    local tool=$(builtin type -p "$1")
    local rv=$RET_UNAV

    # make sure it's really there
    if [ -z "$tool" ]; then
        type "$1" > /dev/null 2>&1
        rv=$?
    else
        rv=$RET_OK
    fi

    return $rv
}

#
# @brief check function presence
#
verify_function_presence() {
    local tool=$(builtin type -t "$1")
    local rv=$RET_UNAV
    local status=0

    # make sure it's really there
    if [ -z "$tool" ]; then
        type "$1" > /dev/null 2>&1;
        status=$?
        [ "$status" -ne $RET_OK ] && tool='empty'
    fi
        
    # check the output
    [ "$tool" = "function" ] && rv=$RET_OK
    return $rv
}

################################## DB ##########################################

# that was an experiment which I decided to drop after all. 
# those functions provide a mechanism to generate consistently named global vars
# i.e. _db_set "abc" 1 will create glob. var ___g_db___abc=1
# left as a reference - do not use it

## #
## # @global prefix for the global variables generation
## #
## g_GlobalPrefix="___g_db___"
## 
## 
## #
## # @brief get variable from the db
## #
## _db_get() {
##  eval "echo \$${g_GlobalPrefix}_$1"  
## }
## 
## 
## #
## # @brief set variable in the db
## #
## _db_set() {
##  eval "${g_GlobalPrefix}_${1/./_}=\$2"
## }

######################################################################## 

