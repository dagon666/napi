#!/bin/bash

# force indendation settings
# vim: ts=4 shiftwidth=4 expandtab

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
#
declare -a g_output=( 1 'none' 0 1 )

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
    tr '[:upper:]' '[:lower:]'
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
        [ "$i" != "$key" ] && rv=( "${rv[@]}" "$i" )
    done

    rv=( "${rv[@]}" "$key=$value" )
    echo ${rv[*]}

    return $RET_OK
}


#
# determines number of available cpu's in the system
#
get_cores() {
    grep -i processor /proc/cpuinfo | count_lines
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
    grep -o "HTTP/[\.0-9]* [0-9]*"
}

################################## STDOUT ######################################

#
# @brief produce output
#
_blit() {
    printf "#%02d:%04d %s\n" ${g_output[2]} ${g_output[3]} "$*"
    g_output[3]=$(( g_output[3] + 1 ))
}


#
# @brief print a debug verbose information
#
_debug() {
    local line=${1:-0} && shift
    [ "${g_output[0]}" -ge 3 ] && _blit "--- $line: $*"
    return $RET_OK
}


#
# @brief print information 
#
_info() {
    local line=${1:-0} && shift
    [ "${g_output[0]}" -ge 2 ] && _blit "-- $line: $*"
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
    local tmp="${g_output[0]}"
    g_output[0]=1
    _status "ERROR" "$*" | to_stderr
    g_output[0]="$tmp"
    return $RET_OK
}


#
# @brief print standard message
#
_msg() {
    [ "${g_output[0]}" -ge 1 ] && _blit "- $*"
    return $RET_OK
}


#
# @brief print status type message
#
_status() {
    [ "${g_output[0]}" -ge 1 ] && _blit "$1 -> $2"
    return $RET_OK
}


#
# @brief redirect errors to standard error output
#
to_stderr() {
    if [ -n "${g_output[1]}" ] && [ "${g_output[1]}" != "none" ]; then
        cat > /dev/stderr
    else
        cat
    fi
}


#
# @brief redirect stdout to logfile
#
redirect_to_logfile() {
    [ -n "${g_output[1]}" ] && [ "${g_output[1]}" != "none" ] && exec 3>&1 1> "${g_output[1]}"
}


#
# @brief redirect output to stdout
#
redirect_to_stdout() {
    [ -n "${g_output[1]}" ] && [ "${g_output[1]}" != "none" ] && exec 1>&3 3>&-
}

################################################################################
