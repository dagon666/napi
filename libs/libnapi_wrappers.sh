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
# A set of independent wrappers for system commands. The rules of thumb for the
# wrapper to be placed here are:
#
# - no dependency on other libraries
# - doesn't fall back into responsibility of other library
# - doesn't require configuration or global variables
#

########################################################################

#
# @brief returns numeric value even for non-numeric input
#
wrappers_ensureNumeric_SO() {
    echo $(( $1 + 0 ))
}

#
# @brief count the number of lines in a file
#
wrappers_countLines_SO() {

    # it is being executed in a subshell to strip any leading white spaces
    # which some of the wc versions produce

    # shellcheck disable=SC2046
    # shellcheck disable=SC2005
    echo $(wc -l)
}

#
# @brief lowercase the input
#
wrappers_lcase_SO() {
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
wrappers_stripNewLine_SO() {
    tr -d '\r\n'
}

#
# @brief get the extension of the input
#
wrappers_getExt_SO() {
    echo "${1##*.}"
}

#
# @brief strip the extension of the input
#
wrappers_stripExt_SO() {
    echo "${1%.*}"
}

#
# @brief detects running system type
#
wrappers_getSystem_SO() {
    uname | wrappers_lcase_SO
}

wrappers_isSystemDarwin() {
    [ "$(wrappers_getSystem_SO)" = "darwin" ]
}

#
# @brief determines number of available cpu's in the system
#
# @param system type (linux|darwin)
#
wrappers_getCores_SO() {
    local os="${1:-linux}"
    if wrappers_isSystemDarwin; then
        sysctl hw.ncpu | cut -d ' ' -f 2
	else
        grep -i processor /proc/cpuinfo | wc -l
    fi
}

################################## FLOAT CMP ###################################

wrappers_floatLt() {
    awk -v n1="$1" -v n2="$2" 'BEGIN{ if (n1<n2) exit 0; exit 1}'
}


wrappers_floatGt() {
    awk -v n1="$1" -v n2="$2" 'BEGIN{ if (n1>n2) exit 0; exit 1}'
}


wrappers_floatLe() {
    awk -v n1="$1" -v n2="$2" 'BEGIN{ if (n1<=n2) exit 0; exit 1}'
}


wrappers_floatGe() {
    awk -v n1="$1" -v n2="$2" 'BEGIN{ if (n1>=n2) exit 0; exit 1}'
}


wrappers_floatEq() {
    awk -v n1="$1" -v n2="$2" 'BEGIN{ if (n1==n2) exit 0; exit 1}'
}

wrappers_floatDiv() {
    awk -v n1="$1" -v n2="$2" 'BEGIN { print n1/n2 }'
}

wrappers_floatMul() {
    awk -v n1="$1" -v n2="$2" 'BEGIN { print n1*n2 }'
}

# EOF
