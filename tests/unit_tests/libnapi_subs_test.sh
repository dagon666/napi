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
. ../../libs/libnapi_sysconf.sh
. ../../libs/libnapi_wrappers.sh

# fakes/mocks
. fake/libnapi_logging_fake.sh
. mock/scpmocker.sh

# module under test
. ../../libs/libnapi_subs.sh

#
# tests env setup
#
setUp() {

    # restore original values
    ___g_subs_defaultExtension='txt'
    sysconf_setKey_GV napiprojekt.subtitles.extension 'txt'
    scpmocker_setUp
}

#
# tests env tear down
#
tearDown() {
    scpmocker_tearDown
}

test_subs_getSubFormatExtension_SO_returnsExpectedExtensions() {
    local formats=( 'subrip' 'subviewer2' 'other' \
        'non-existing-format' )
    local defaultExt="$(sysconf_getKey_SO napiprojekt.subtitles.extension)"
    local expected=( 'srt' 'sub' \
        "$defaultExt" "$defaultExt" )

    local idx=
    for idx in "${!formats[@]}"; do
        local f="${formats[$idx]}"
        local e="${expected[$idx]}"

        assertEquals "checking extension for format [$f]" \
            "$e" "$(subs_getSubFormatExtension_SO "$f")"
    done
}

test_subs_getDefaultExtension_SO_returnsTheGlobalVariableValue() {
    local value=
    for value in "{a..z}{a..z}"; do
        sysconf_setKey_GV napiprojekt.subtitles.extension "$value"
        assertEquals "check return value" \
            "$value" "$(subs_getDefaultExtension_SO)"
    done
}

test_subs_getCharset_failsIfFileToolIsNotDetected() {
    local subsFile=$(mktemp -p "${SHUNIT_TMPDIR}")

    scpmocker_patchFunction tools_isDetected
    scpmocker -c func_tools_isDetected program -e 1

    subs_getCharset_SO "$subsFile"

    assertEquals "check exit value" \
        "$G_RETFAIL" "$?"

    scpmocker_resetFunction tools_isDetected
}

test_subs_getCharset_detectsAllSupportedCharsets() {
    local subsFile=$(mktemp -p "${SHUNIT_TMPDIR}")

    scpmocker_patchCommand file
    scpmocker_patchFunction tools_isDetected

    scpmocker -c func_tools_isDetected program -e 0
    scpmocker -c file program -s "utf-8"
    scpmocker -c file program -s "utf8"
    scpmocker -c file program -s "iso-885"
    scpmocker -c file program -s "us-ascii"
    scpmocker -c file program -s "csascii"
    scpmocker -c file program -s "ascii"
    scpmocker -c file program -s "other"

    assertEquals "check output for charset utf" \
        "UTF8" "$(subs_getCharset_SO "$subsFile")"

    assertEquals "check output for charset utf" \
        "UTF8" "$(subs_getCharset_SO "$subsFile")"

    assertEquals "check output for charset iso" \
        "ISO-8859-2" "$(subs_getCharset_SO "$subsFile")"

    assertEquals "check output for charset usascii" \
        "US-ASCII" "$(subs_getCharset_SO "$subsFile")"

    assertEquals "check output for charset csascii" \
        "CSASCII" "$(subs_getCharset_SO "$subsFile")"

    assertEquals "check output for charset ascii" \
        "ASCII" "$(subs_getCharset_SO "$subsFile")"

    assertEquals "check output for charset ascii" \
        "WINDOWS-1250" "$(subs_getCharset_SO "$subsFile")"

    scpmocker_resetFunction tools_isDetected
}

test_subs_convertEncodingDoesntOverwriteOriginalIfConversionFails() {
    local subsFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local convFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local testData="Mary had a little lamb"

    scpmocker_patchCommand iconv
    scpmocker_patchFunction subs_getCharset_SO
    scpmocker_patchFunction fs_mktempFile_SO

    # iconv failure
    scpmocker -c iconv program -e 1
    scpmocker -c func_subs_getCharset_SO program -s "UTF8"
    scpmocker -c func_fs_mktempFile_SO program -s "$convFile"

    echo "$testData" > "$subsFile"
    local expectedHash=$(sha256sum "$subsFile" | awk '{ print $1 }')

    subs_convertEncoding "$subsfile" "some encoding"

    local dataHash=$(sha256sum "$subsFile" | awk '{ print $1 }')

    assertEquals "compare file hashes" \
        "$expectedHash" "$dataHash"

    assertEquals "check iconv's mock call count" \
        "1" "$(scpmocker -c iconv status -C)"

    scpmocker_resetFunction subs_getCharset_SO
    scpmocker_resetFunction fs_mktempFile_SO
}

test_subs_convertEncodingReplacesTheFileIfConversionSuccessful() {
    local subsFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local convFile=$(mktemp -p "${SHUNIT_TMPDIR}")

    scpmocker_patchCommand iconv
    scpmocker_patchCommand mv
    scpmocker_patchFunction subs_getCharset_SO
    scpmocker_patchFunction fs_mktempFile_SO

    # iconv failure
    scpmocker -c iconv program -e 0
    scpmocker -c func_subs_getCharset_SO program -s "UTF8"
    scpmocker -c func_fs_mktempFile_SO program -s "$convFile"

    subs_convertEncoding "$subsfile" "some encoding"

    assertEquals "check iconv's mock call count" \
        "1" "$(scpmocker -c iconv status -C)"

    assertEquals "check mv's mock call count" \
        "1" "$(scpmocker -c mv status -C)"

    scpmocker_resetFunction subs_getCharset_SO
    scpmocker_resetFunction fs_mktempFile_SO
}

# shunit call
. shunit2
