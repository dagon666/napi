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
# @brief aggregates all collected titles from the command line
#
declare -a ___g_movieTitles=()

#
# @brief title's release year
#
___g_movieYear=

#
# @brief title's type (0 - movie or 1 - series)
#
___g_titleType=

########################################################################

_search_argvDispatcher_GV() {
    case "$1" in
        "-y" | "--year")
            ___g_argvOutputHandlerType="var"
            ___g_argvOutputHandler='___g_movieYear'
            ___g_argvErrorMsg=$"nie okreslono roku"
            ;;

        "-k" | "--kind")
            ___g_argvOutputHandlerType="var"
            ___g_argvOutputHandler='___g_titleType'
            ___g_argvErrorMsg=$"nie okreslono typu <movie|series"
            ;;

        *)
            ___g_movieTitles=( "${___g_movieTitles[@]}" "$1" )
            ;;
    esac
}

_search_normalizeOptions() {
    [ -n "$___g_movieYear" ] &&
        ___g_movieYear=$(wrappers_ensureNumeric_SO "$___g_movieYear")

    case "$___g_titleType" in
        "movie") ___g_titleType=0 ;;
        "series") ___g_titleType=1 ;;
        *) ___g_titleType='' ;;
    esac
}

#
# @brief parse search specific options
#
# This function modifies ___g_movieTitles array
#
_search_parseArgv_GV() {
    logging_debug $LINENO $"parsuje opcje akcji search"
    argv_argvParser_GV _search_argvDispatcher_GV "$@" &&
        _search_normalizeOptions
}

#
# @brief get information for a single title
#
_search_searchTitle() {
    local postData="queryString=${1}"
    local awkCode=

    postData="${postData}&queryKind=${___g_titleType}"
    postData="${postData}&queryYear=${___g_movieYear}"
    postData="${postData}&associate="

read -r -d "" awkCode << 'SEARCHTITLEAWKEOF'
/movieTitleCat/ {
    isTitleMatched = match($0, /tytul="([^"]*)"/, cTitle)
    isIdMatched = match($0, /id="([^"]*)"/, cId)
    isHrefMatched = match($0, /href="([^"]*)"/, cHref)

    if (isIdMatched && isTitleMatched && isHrefMatched) {
        printf(" %6d | %s | %s\n", cId[1], cTitle[1], (napiBase "/" cHref[1]))
    }
}
SEARCHTITLEAWKEOF

    http_downloadUrl_SOSE \
        "${g_napiprojektBaseUrl}${g_napiprojektMovieCatalogueSearchUri}" \
        "" "$postData" 2>/dev/null | \
        awk -v napiBase="$g_napiprojektBaseUrl" "$awkCode"
}

#
# @brief iterate through provided titles and get movie information for
# every each of them
#
_search_searchTitles() {
    local title=
    for title in "${___g_movieTitles[@]}"; do
        logging_msg $"Wyszukuje tytul:" "[$title]"
        _search_searchTitle "$title" || return $G_RETFAIL
    done
    return $G_RETOK
}

#
# @brief print usage description for search action
#
search_usage() {
    echo $"napi.sh search [OPCJE] <tytul filmu|...>"
    echo
    echo $"OPCJE:"
    echo $" -y | --year <rok> - szukaj tytulu z danego roku"
    echo $" -k | --kind <movie|series> - tytul hest filmem badz serialem"
}

#
# @brief entry point for search action
#
search_main() {
    # parse search specific options
    _search_parseArgv_GV "$@"

    logging_debug $LINENO "Title type: ${___g_titleType}"
    logging_debug $LINENO "Movie year: ${___g_movieYear}"

    # search the movies
    _search_searchTitles
}
