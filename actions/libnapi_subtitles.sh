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

########################################################################

# globals

#
# @brief aggregates all collected movie page urls
#
declare -a ___g_moviePageUrls=()

########################################################################

_subtitles_getSubtitlesForUrl() {
    local url="$1"
}

#
# @brief attempts to extract the url to subtitles page of given movie
# and extract subtitles ids for that movie
#
_subtitles_getSubtitles() {
    local url=
    for url in "${___g_moviePageUrls[@]}"; do
        logging_msg $"Przetwarzam: " "[$url]"
        _subtitles_getSubtitlesForUrl "$url" || return $G_RETFAIL
    done
    return $G_RETOK
}

_subtitles_argvDispatcher_GV() {
    case "$1" in
        *)
            ___g_moviePageUrls=( "${___g_moviePageUrls[@]}" "$1" )
            ;;
    esac
}

#
# @brief parse search specific options
#
# This function modifies ___g_movieTitles array
#
_subtitles_parseArgv_GV() {
    logging_debug $LINENO $"parsuje opcje akcji search"
    argv_argvParser_GV _subtitles_argvDispatcher_GV "$@"
}

#
# @brief print usage description for subtitles action
#
subtitles_usage() {
    echo $"napi.sh subtitles [OPCJE] <movie_page_url>"
    echo
    echo $"OPCJE:"
    echo
}

#
# @brief entry point for search action
#
subtitles_main() {
    # parse search specific options
    _subtitles_parseArgv_GV "$@"

    # search for subtitles ids
    _subtitles_getSubtitles
}

# EOF
