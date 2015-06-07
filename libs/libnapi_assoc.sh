#!/bin/bash

# force indendation settings
# vim: ts=4 shiftwidth=4 expandtab

########################################################################
########################################################################
########################################################################

#  Copyright (C) 2017 Tomasz Wisniewski aka
#       DAGON <tomasz.wisni3wski@gmail.com>
#
#  http://github.com/dagon666
#  http://pcarduino.blogspot.co.uk
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

#
# @brief generic group lookup function
# @param group name
# @param extract function
# @param array
#
_assoc_groupLookupGeneric_SO() {
    local i=''
    local results=''
    local group="${1}" && shift
    local extractor="${1}" && shift

    for i in $*; do
        local tg=$(assoc_getGroup_SO "$i")
        if [ -n "$tg" ] && [ "$tg" = "$group" ]; then
            local tk=$("$extractor" "$i")
            results="$results $tk"
        fi
    done

    [ -n "$results" ] && echo "$results"
}

########################################################################

#
# @brief get the group from strings like group:key=value or key=value
#
assoc_getGroup_SO() {
    local k="${1%=*}"
    echo "${k%%:*}"
}


#
# @brief get the value from strings like group:key=value or key=value
#
assoc_getValue_SO() {
    echo "${1##*=}"
}

#
# @brief get the key from strings like group:key=value or key=value
#
assoc_getKey_SO() {
    local k="${1%=*}"
    echo "${k#*:}"
}

#
# @brief search for specified key and return it's value
# @param key
# @param array
#
assoc_lookupValue_SO() {
    local i=''
    local key="$1" && shift
    local tk=''

    # using $* is deliberate to allow parsing either array or space delimited strings

    # shellcheck disable=SC2048
    for i in $*; do
        tk=$(assoc_getKey_SO "$i")
        if [ "$tk"  = "$key" ]; then
            assoc_getValue_SO "$i"
            return $G_RETOK
        fi
    done

    return $G_RETFAIL
}

#
# @brief modify value in the array (it will be added if the key doesn't exist)
# @param key
# @param value
# @param array
#
assoc_modifyValue_SO() {
    local key=$1 && shift
    local value=$1 && shift

    local i=0
    local k=''
    declare -a rv=()

    # shellcheck disable=SC2048
    for i in $*; do
        k=$(assoc_getKey_SO "$i")
        # unfortunately old shells don't support rv+=( "$i" )
        [ "$k" != "$key" ] && rv=( "${rv[@]}" "$i" )
    done

    rv=( "${rv[@]}" "$key=$value" )
    echo ${rv[*]}
}

#
# @brief lookup index in the array for given value
# returns the index of the value and 0 on success
#
assoc_lookupKey_SO() {
    local i=''
    local idx=0
    local rv=$G_RETFAIL
    local key="$1"

    shift
    for i in "$@"; do
        [ "$i" = "$key" ] && rv=$G_RETOK && break
        idx=$(( idx + 1 ))
    done

    echo $idx
    return $rv
}

#
# @brief search for specified group and return it's keys as string
# @param group
# @param array
#
assoc_lookupGroupKeys_SO() {
    local group="${1}" && shift
    _assoc_groupLookupGeneric_SO "$group" "assoc_getKey_SO" "$@"
}

#
# @brief extract a key=value from an entry of form [group:]key=value
#
assoc_getKvPair_SO() {
    echo "${1##*:}"
}

#
# @brief search for specified group and return it's keys=value pairs as string
# @param group
# @param array
#
assoc_lookupGroupKv_SO() {
    local group="${1}" && shift
    _assoc_groupLookupGeneric_SO "$group" "assoc_getKvPair_SO" "$@"
}

# EOF
