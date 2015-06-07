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

# globals
___g_wget='none'

########################################################################

_http_configureWget() {
    local wget_cmd='wget -q -O'
    local wget_post=0

    local s_test=$(wget --help 2>&1 | grep "\-S")
    [ -n "$s_test" ] && wget_cmd='wget -q -S -O'

    local p_test=$(wget --help 2>&1 | grep "\-\-post\-")
    [ -n "$p_test" ] && wget_post=1

    # Entry format is:
    # <POST_SUPPORT=0|1>|<WGET_CMD>
    ___g_wget="$wget_post|$wget_cmd"

    # shellcheck disable=SC2086
    return $RET_OK
}

########################################################################

#
# @brief configure the library
#
http_configure_GV() {
    [ "$___g_wget" = 'none' ] && _http_configureWget
}

#
# @brief execute wget
#
http_wget() {
    ${___g_wget##[0-9]*|} "$@"
}

#
# @brief return true if wget supports POST
#
http_isPostRequestSupported() {
    [ "${___g_wget%%|*}" -eq 1 ]
}

#
# @brief extract http status code
#
http_getHttpStatus() {
    # grep -o "HTTP/[\.0-9]* [0-9]*"
    awk '{ m = match($0, /HTTP\/[\.0-9]* [0-9]*/); if (m) print substr($0, m, RLENGTH) }'
}

#
# @brief wrapper for wget
# @param url
# @param output file (or stdout)
# @param POST data - if set the POST request will be done instead of GET (default)
#
# @requiers libnapi_io
#
# returns data on stdout or to a specified file
# returns the http code(s) on stderr
#
http_downloadUrl_SOSE() {
    local url="$1"
    local output="${2:-/dev/stdout}"

    local post="${3:-}"
    local postParams=()

    [ -n "$url" ] ||
        return $G_RETFAIL

    [ -n "$post" ] && \
        http_isPostRequestSupported && \
        postParams=( "--post-data=${post}" )

    http_wget "$output" \
        "${postParams[@]}" \
        "$url" \
        2> >(http_getHttpStatus | cut -d ' ' -f 2 >&2)
}

########################################################################
