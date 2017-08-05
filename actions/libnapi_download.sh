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
# @brief aggregates all collected subtitle hashes
#
declare -a ___g_subHashes=()

___g_downloadMovieTitleFileName=0

########################################################################

#
# @brief parse the cli arguments
#
_download_argvDispatcher_GV() {
    case "$1" in
        "-t" | "--title")
            ___g_downloadMovieTitleFileName=1
            ;;

        "-c" | "--cover")
            sysconf_setKey_GV napiprojekt.cover.download 1
            ;;

        "-n" | "--nfo")
            sysconf_setKey_GV napiprojekt.nfo.download 1
            ;;

        "-e" | "--ext")
            ___g_argvOutputHandlerType="func"
            ___g_argvOutputHandler='sysconf_setKey_GV napiprojekt.subtitles.extension'
            ___g_argvErrorMsg=$"nie okreslono domyslnego rozszerzenia dla pobranych plikow"
            ;;

            *)
            # shellcheck disable=SC2155
            local normalizedHash="$(napiprojekt_normalizeHash_SO "$1")"
            ___g_subHashes=( "${___g_subHashes[@]}" "$normalizedHash" )
            ;;
    esac
}

_download_parseArgv_GV() {
    logging_debug $LINENO $"parsuje opcje akcji download"
    argv_argvParser_GV _download_argvDispatcher_GV "$@"
}

_download_getSubtitlesForHashes() {
    local lang="$(language_getLanguage_SO)"
    local subsExt=$(subs_getDefaultExtension_SO)
    local coverExt=$(sysconf_getKey_SO napiprojekt.cover.extension)
    local nfoExt=$(sysconf_getKey_SO napiprojekt.nfo.extension)

    local downloadNfo=$(sysconf_getKey_SO napiprojekt.nfo.download)
    local downloadCover=$(sysconf_getKey_SO napiprojekt.cover.download)

    logging_info $LINENO $"pobieram napisy w jezyku" "[$lang]"

    for h in "${___g_subHashes[@]}"; do
        local xmlFile="$(fs_mktempFile_SO)"

        if napiprojekt_downloadXml "$h" "" "0" "$xmlFile" "$lang" &&
            napiprojekt_verifyXml "$xmlFile"; then
            local subsFile=

            [ "$___g_downloadMovieTitleFileName" -eq 1 ] && {
                logging_debug $LINENO $"ekstrakcja tytulu z XML"
                subsFile="$(napiprojekt_extractTitleFromXml_SO "$xmlFile")"
            }

            [ -z "$subsFile" ] && {
                logging_debug $LINENO $"XML nie zawiera tytulu"
                subsFile="${h}"
            }

            napiprojekt_extractSubsFromXml "$xmlFile" \
                "${subsFile}.${subsExt}" &&
                logging_msg $"napisy pobrano pomyslnie" "[$h]"

            [ "$downloadNfo" -eq 1 ] && {
                logging_debug $LINENO $"tworze plik nfo"
                napiprojekt_extractNfoFromXml "$xmlFile" \
                    "${subsFile}.${nfoExt}" &&
                    logging_msg $"plik nfo utworzony pomyslnie" "[$h]"
            }

            [ "$downloadCover" -eq 1 ] && {
                logging_debug $LINENO $"wypakowuje okladke z XML"
                napiprojekt_extractCoverFromXml "$xmlFile" \
                    "${subsFile}.${coverExt}" &&
                    logging_msg $"okladka pobrana pomyslnie" "[$h]"
            }
        fi
    done
}

########################################################################

download_usage() {
    echo $"napi.sh download [OPCJE] <napiprojekt:id|*>"
    echo
    echo $"OPCJE:"
    echo $" -c | --cover - pobierz okladke"
    echo $" -n | --nfo - utworz plik z informacjami o napisach"
    echo $" -t | --title - nazwa pliku jak tytul"
    echo $" -e | --ext - rozszerzenie dla pobranych napisow (domyslnie *.txt)"
}

download_main() {
    # parse search specific options
    _download_parseArgv_GV "$@" || {
        logging_debug $"blad parsera download"
        return $G_RETFAIL
    }

    # process hashes
    _download_getSubtitlesForHashes
    return $G_RETOK
}

# EOF
