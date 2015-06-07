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

# global

#
# global paths list
#
declare -a g_scan_paths=()

#
# global files list
#
declare -a g_scan_files=()

########################################################################

_scan_argvDispatcher_GV() {

}

_scan_parseArgv_GV() {
    logging_debug $LINENO $"parsuje opcje akcji scan"
    argv_argvParser_GV _scan_argvDispatcher_GV "$@"
}

########################################################################

#
# @brief print usage description for subtitles action
#
scan_usage() {
    echo $"napi.sh scan [OPCJE] <plik|katalog|*>"
    echo
    echo $"OPCJE:"
    echo $" -c | --cover - pobierz okladke"
    echo $" -n | --nfo - utworz plik z informacjami o napisach"
    echo $" -e | --ext - rozszerzenie dla pobranych napisow (domyslnie *.txt)"
    echo $" -b | --bigger-than <size MB> - skanuj pliki wieksze niz <size>"
    echo $" -F | --forks - okresl recznie ile rownoleglych procesow utworzyc"
    echo $" -M | --move - w przypadku opcji (-s) przenos pliki, nie kopiuj"
    echo $" -a | --abbrev <string> - dodaj dowolny string przed rozszerzeniem (np. nazwa.<string>.txt)"
    echo $" -s | --skip - nie sciagaj, jezeli napisy juz sciagniete"
    echo $"    | --stats - wydrukuj statystyki (domyslnie nie beda drukowane)"

    echo
    echo "Przyklady:"
    echo " napi.sh film.avi          - sciaga napisy dla film.avi."
    echo " napi.sh -c film.avi       - sciaga napisy i okladke dla film.avi."
    echo " napi.sh -u foo -p bar -c film.avi - sciaga napisy i okladke do"
    echo "                             film.avi jako uzytkownik foo"
    echo " napi.sh *                 - szuka plikow wideo w obecnym katalogu"
    echo "                             i podkatalogach, po czym stara sie dla"
    echo "                             nich znalezc i pobrac napisy."
    echo " napi.sh *.avi             - wyszukiwanie tylko plikow avi."
    echo " napi.sh katalog_z_filmami - wyszukiwanie we wskazanym katalogu"
    echo "                             i podkatalogach."
}

#
# @brief entry point for search action
#
scan_main() {
    # parse search specific options
    _scan_parseArgv_GV "$@" || {
        logging_debug $"blad parsera scan"
        return $G_RETFAIL
    }

    # process hashes
    _scan_getSubtitlesForFiles
    return $G_RETOK
}

# EOF
