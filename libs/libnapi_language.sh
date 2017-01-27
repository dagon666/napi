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

# globals
___g_language_napiprojektLanguage='PL'

#
# napiprojekt supported languages
#
declare -ar ___g_napiprojektLanguages=( 'Albański' 'Angielski' 'Arabski' 'Bułgarski' \
    'Chiński' 'Chorwacki' 'Czeski' 'Duński' \
    'Estoński' 'Fiński' 'Francuski' 'Galicyjski' \
    'Grecki' 'Hebrajski' 'Hiszpanski' 'Holenderski' \
    'Indonezyjski' 'Japoński' 'Koreański' 'Macedoński' \
    'Niemiecki' 'Norweski' 'Oksytański' 'Perski' \
    'Polski' 'Portugalski' 'Portugalski' 'Rosyjski' \
    'Rumuński' 'Serbski' 'Słoweński' 'Szwedzki' \
    'Słowacki' 'Turecki' 'Wietnamski' 'Węgierski' 'Włoski' )

#
# napiprojekt 2 Letter language codes
#
declare -ar ___g_napiprojektLanguageCodes2L=( 'SQ' 'EN' 'AR' 'BG' 'ZH' 'HR' \
    'CS' 'DA' 'ET' 'FI' 'FR' 'GL' 'EL' 'HE' 'ES' 'NL' 'ID' 'JA' 'KO' 'MK' \
    'DE' 'NO' 'OC' 'FA' 'PL' 'PT' 'PB' 'RU' 'RO' 'SR' 'SL' 'SV' 'SK' 'TR' \
    'VI' 'HU' 'IT' )

#
# napiprojekt 3 Letter language codes
#
declare -ar ___g_napiprojektLanguageCodes3L=( 'ALB' 'ENG' 'ARA' 'BUL' 'CHI' \
    'HRV' 'CZE' 'DAN' 'EST' 'FIN' 'FRE' 'GLG' 'ELL' 'HEB' 'SPA' 'DUT' 'IND' \
    'JPN' 'KOR' 'MAC' 'GER' 'NOR' 'OCI' 'PER' 'POL' 'POR' 'POB' 'RUS' 'RUM' \
    'SCC' 'SLV' 'SWE' 'SLO' 'TUR' 'VIE' 'HUN' 'ITA' )

########################################################################

#
# @brief list all the supported languages and their respective 2/3 letter codes
#
language_listLanguages_SO() {
    local i=0
    while [ "$i" -lt "${#___g_napiprojektLanguages[@]}" ]; do
        echo "${___g_napiprojektLanguageCodes2L[$i]} /" \
            "${___g_napiprojektLanguageCodes3L[$i]} - ${___g_napiprojektLanguages[$i]}"
        i=$(( i + 1 ))
    done
}

#
# @brief verify that the given language code is supported
#
language_verifyLanguage_SO() {
    local i=0
    local lang="${1:-}"
    local langArray=( )

    # shellcheck disable=SC2086
    [ "${#lang}" -ne 2 ] && [ "${#lang}" -ne 3 ] && return $G_RETPARAM

    local langArrayName="___g_napiprojektLanguageCodes${#lang}L"
    eval langArray=\( \${${langArrayName}[@]} \)

    i=$(assoc_lookupKey_SO "$lang" "${langArray[@]}")
    local found=$?

    [ $? -eq $G_RETOK ] && {
        echo "$i"
        return $G_RETOK
    }

    # shellcheck disable=SC2086
    return $RET_FAIL
}

#
# @brief set the language variable
# @param: language index
#
language_normalizeLanguage_SO() {
    local i=${1:-0}
    i=$(( i + 0 ))
    local lang="${___g_napiprojektLanguageCodes2L[$i]}"
    # don't ask me why
    [ "$lang" = "EN" ] && lang="ENG"
    echo "$lang"
}

#
# @brief set language
#
language_setLanguage_GV() {
    local idx=0
    ___g_language_napiprojektLanguage="${1}"

    idx=$(language_verifyLanguage_SO "$___g_language_napiprojektLanguage") || {
        logging_error $"niepoprawny kod jezyka" "[$1]"
        ___g_language_napiprojektLanguage="PL"
    }

    ___g_language_napiprojektLanguage=$(language_normalizeLanguage_SO "$idx")
    logging_debug $LINENO $"jezyk skonfigurowany jako" \
        "[$___g_language_napiprojektLanguage]"
}

#
# @brief return language configured
#
language_getLanguage_SO() {
    echo "$___g_language_napiprojektLanguage"
}

# EOF
