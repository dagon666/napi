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
# @brief global tools array
# =1 - mandatory tool
# =0 - optional tool
#
# Syntax: [group:]<key1|key2|...>=<value>
#
declare -a ___g_tools=( 'tr=1' 'printf=1' 'mktemp=1' 'wget=1' \
    'wc=1' 'dd=1' 'grep=1' 'seq=1' 'sed=1' 'cut=1' \
    'base64=1' 'unlink=0' 'stat=1' 'basename=1' \
    'dirname=1' 'cat=1' 'cp=1' 'mv=1' 'awk=1' \
    'file=0' 'iconv=0' '7z|7za=0' 'md5|md5sum=1' \
    'fps:mediainfo=0' 'fps:mplayer|mplayer2=0' 'fps:ffmpeg|ffprobe=0' )

########################################################################

#
# @brief verify all the registered tools from the tools array
#
tools_configure_GV() {
    # this function can cope with that kind of input
    # shellcheck disable=SC2068
    ___g_tools=( $(tools_verify_SO "${___g_tools[@]}") )
}

#
# @brief check function presence
# @param function name
#
tools_verifyFunctionPresence() {
    local tool=$(builtin type -t "$1")

    # make sure it's really there
    if [ -z "$tool" ]; then
        type "$1" >/dev/null 2>&1 || tool='empty'
    fi

    # check the output
    [ "$tool" = "function" ]
}

#
# @brief checks if the tool is available in the PATH
#
tools_verifyToolPresence() {
    local tool=$(builtin type -p "$1")
    local rv=$G_RETUNAV

    # make sure it's really there
    if [ -z "$tool" ]; then
        type "$1" >/dev/null 2>&1
        rv=$?
    else
        rv=$G_RETOK
    fi
    return $rv
}

#
# @brief append given tool to tools array
# @param tool name
# @param requirement (optional): 1 - required (default), 0 - optional
#
tools_addTool_GV() {
    logging_debug $LINENO $"dodaje narzedzie: " "[$1]"

    # g_tools+=( "$1=${2:-1}" )
    ___g_tools=( "${___g_tools[@]}" "$1=${2:-1}" )
}

#
# @brief perform tools presence verification
#
tools_verify_SO() {
    local ret=()
    local t=''

    for t in "$@"; do
        # obtain each tool's attributes
        local key=$(assoc_getKey_SO "$t")
        local mandatory=$(assoc_getValue_SO "$t")
        local group="$(assoc_getGroup_SO "$t")"

        local tool=
        local counter=0

        # iterate over group optionals
        for tool in ${key//|/ }; do
            local presence=1
            local entry=

            tools_verifyToolPresence "$tool" || presence=0
            entry="${tool}=${presence}"

            # if group definition is present prepend it to the entry
            [ -n "$group" ] &&
                entry="${group}:${entry}"

            # append the entry to the array
            ret=( "${ret[@]}" "$entry" )

            # increment detected counter if tool is present
            [ "$presence" -eq 1 ] &&
                counter=$(( counter + 1 ))
        done

        # break if mandatory tool is missing
        [ "$mandatory" -eq 1 ] && [ "$counter" -eq 0 ] &&
            return $G_RETFAIL
    done

    # shellcheck disable=SC2086
    echo ${ret[*]}
}

#
# @brief check if given tool has been detected
# @param tool name
#
tools_isDetected() {
    # this function can cope with that kind of input
    # shellcheck disable=SC2068
    local t=
    t="$(assoc_lookupValue_SO "$1" "${___g_tools[@]}" )"
    t=$(wrappers_ensureNumeric_SO "$t")
    [ "$t" -eq 1 ]
}

#
# @brief get first available tool from given group
# @param group name
# @param
#
tools_getFirstAvailableFromGroup_SO() {
    local t=''
    for t in $(assoc_lookupGroupKeys_SO "${1:-none}" "${___g_tools[@]}"); do
        tools_isDetected "$t" && {
            echo "$t"
            return $G_RETOK
        }
    done

    # shellcheck disable=SC2086
    return $G_RETUNAV
}

#
# @brief check if given tool belongs to given group
# @param group name
# @param tool name
#
tools_isInGroup() {
    local t=''
    for t in $(assoc_lookupGroupKeys_SO "${1:-none}" "${___g_tools[@]}"); do
        # shellcheck disable=SC2086
        [ "$t" = "${2:-none}" ] && return $G_RETOK
    done

    logging_info $LINENO "$2" $"nie znajduje sie w grupie" "$1"
    # shellcheck disable=SC2086
    return $G_RETUNAV
}

#
# @brief return first detected tool from a given group
#
tools_isInGroupAndDetected() {
    local t=''
    for t in $(assoc_lookupGroupKeys_SO "${1:-none}" "${___g_tools[@]}"); do
        # shellcheck disable=SC2086
        [ "$t" = "${2:-none}" ] &&
            tools_isDetected "$t" &&
            return $G_RETOK
    done

    logging_info $LINENO \
        "$2" $"nie znajduje sie w grupie" "$1" $", badz nie zostal wykryty"

    # shellcheck disable=SC2086
    return $G_RETUNAV
}

#
# @brief returns the number of tools in the group
# @param group name
#
tools_countGroupMembers_SO() {
    local a=( $(assoc_lookupGroupKeys_SO "${1:-none}" "${___g_tools[@]}") )
    echo "${#a[*]}"
}

#
# @brief returns the number of detected tools in the group
#
tools_countDetectedGroupMembers_SO() {
    local t=''
    local count=0
    for t in $(assoc_lookupGroupKeys_SO "${1:-none}" "${___g_tools[@]}"); do
        # shellcheck disable=SC2086
        tools_isDetected "$t" && count=$(( count + 1 ))
    done

    echo "$count"
}

#
# @brief concat the tools array to single line
#
tools_toString_SO() {
    echo "${___g_tools[*]}"
}

#
# @brief concat the tools array to list
#
tools_toList_SO() {
    ( IFS=$'\n'; echo "${___g_tools[*]}" )
}

#
# @brief concat the group members to single line
# @param group name
#
tools_groupToString_SO() {
    assoc_lookupGroupKv_SO "$1" "${___g_tools[@]}"
}

#
# @brief concat the group members to list
# @param group name
#
tools_groupToList_SO() {
    local a=( $(assoc_lookupGroupKv_SO "$1" "${___g_tools[@]}") )
    ( IFS=$'\n'; echo "${a[*]}" )
}

# EOF
