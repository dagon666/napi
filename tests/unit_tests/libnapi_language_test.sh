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

# module dependencies
. ../../libs/libnapi_assoc.sh
. ../../libs/libnapi_retvals.sh


# fakes/mocks
. fake/libnapi_logging_fake.sh
. mock/scpmocker.sh

# module under test
. ../../libs/libnapi_language.sh

setUp() {
    scpmocker_setUp

    # restore original values
    ___g_language_napiprojektLanguage='PL'
}

tearDown() {
    scpmocker_tearDown
}

test_language_listLanguages_producesOutput() {
    assertNotNull "Output is not empty" \
        "$(language_listLanguages_SO)"
}

test_language_listLanguages_listsAllLanguages() {
    assertEquals "Matches 2 letter codes array size" \
        "${#___g_napiprojektLanguageCodes2L[@]}" \
        "$(language_listLanguages_SO | wc -l)"

    assertEquals "Matches 3 letter codes array size" \
        "${#___g_napiprojektLanguageCodes3L[@]}" \
        "$(language_listLanguages_SO | wc -l)"

    assertEquals "Matches language array size" \
        "${#___g_napiprojektLanguages[@]}" \
        "$(language_listLanguages_SO | wc -l)"
}

test_language_verifyLanguage_verifiesAllSupported2LCodes() {
    local key=
    local lang=

    for k in "${!___g_napiprojektLanguageCodes2L[@]}"; do
        lang="${___g_napiprojektLanguageCodes2L[$k]}"
        key=$(language_verifyLanguage_SO "$lang")
        assertTrue "verify exit status" $?

        assertEquals "verify language [$lang]" \
            "$k" "$key"
    done
}

test_language_verifyLanguage_verifiesAllSupported3LCodes() {
    local key=
    local lang=

    for k in "${!___g_napiprojektLanguageCodes3L[@]}"; do
        lang="${___g_napiprojektLanguageCodes3L[$k]}"
        key=$(language_verifyLanguage_SO "$lang")
        assertTrue "verify exit status" $?

        assertEquals "verify language [$lang]" \
            "$k" "$key"
    done
}

test_language_verifyLanguage_failsForUnknownLanguages() {
    local key=
    local lang=
    local langs=( 'FAKE' 'OT' 'AB' 'DEF' 'XX' )

    for k in "${!langs[@]}"; do
        lang="${langs[$k]}"
        key=$(language_verifyLanguage_SO "$lang")
        assertFalse "verify exit status" $?

        assertNull "verify language [$lang]" \
            "$key"
    done
}

test_language_normalizeLanguage_normalizes2LCodes() {
    local langOutput=
    local lang=

    for k in "${!___g_napiprojektLanguageCodes2L[@]}"; do
        lang="${___g_napiprojektLanguageCodes2L[$k]}"
        langOutput=$(language_normalizeLanguage_SO "$k")
        assertTrue "verify exit status" $?

        [ "$lang" = "EN" ] && lang="ENG"

        assertEquals "normalized code [$lang]" \
            "$lang" "$langOutput"
    done
}

test_language_getLanguage_echoesGlobalValue() {
    for l in {A..Z}{A..Z}; do
        ___g_language_napiprojektLanguage="$l"

        assertEquals "checking output for $l" \
            "$l" "$(language_getLanguage_SO)"
    done
}

test_setLanguage_fallsbackOnVerificationFailure() {
    language_setLanguage_GV "COMPLETE_BOLOCKS"

    assertEquals "checking fallback value" \
        "PL" "$___g_language_napiprojektLanguage"
}

test_setLanguage_worksForAllSupportedCodes() {
    for i in "${!___g_napiprojektLanguageCodes2L[@]}"; do
        lang="${___g_napiprojektLanguageCodes2L[$i]}"
        language_setLanguage_GV "$lang"

        [ "$lang" = "EN" ] && lang="ENG"

        assertEquals "checking language value" \
            "$lang" "$___g_language_napiprojektLanguage"
    done
}

# shunit call
. shunit2
