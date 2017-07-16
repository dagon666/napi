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
. ../../libs/libnapi_assoc.sh
. ../../libs/libnapi_retvals.sh
. ../../libs/libnapi_wrappers.sh

# fakes/mocks
. fake/libnapi_logging_fake.sh
. mock/scpmocker.sh

# module under test
. ../../libs/libnapi_subotage.sh

#
# tests env setup
#
setUp() {
    # restore original values
    ___g_subotageLastingTimeMs=3000
    scpmocker_setUp
    NAPISUBS="${NAPITESTER_TESTDATA}/testdata/subtitles"
}

#
# tests env tear down
#
tearDown() {
    scpmocker_tearDown
}


test_subotage_isFormatSupportedValidatesSupportedFormats() {
    local validFormats=( "microdvd" "mpl2" "subrip" \
        "subviewer2" "tmplayer" )
    local invalidFormats=( "made-up" "other" "abc" "def" )
    local fmt=

    for fmt in "${validFormats[@]}"; do
        subotage_isFormatSupported "$fmt"
        assertTrue "check return value for format [$fmt]" \
            "$?"
    done

    for fmt in "${invalidFormats[@]}"; do
        subotage_isFormatSupported "$fmt"
        assertFalse "check return value for format [$fmt]" \
            "$?"
    done
}

test_subotage_checkFormatMicrodvd_SO_withFakeSubs() {
    local subsFile=$(mktemp -p "${SHUNIT_TMPDIR}")
	local match=

    # insert some subs data
    {
        echo "junk"
        echo "{123}{456}first line"
        echo "{123}{456}second line"
    } > "$subsFile"

	match=$(subotage_checkFormatMicrodvd_SO "$subsFile")
	assertEquals "checking the first line" \
        "microdvd 2" "$match"

    # insert some junk
    {
        echo "junk"
        echo "junk"
        echo "junk"
        echo "junk"
    } > "$subsFile"

	match=$(subotage_checkFormatMicrodvd_SO "$subsFile")
	assertEquals "checking negative detection" \
        "not_detected" "$match"
}

test_subotage_checkFormatMicrodvd_SO_withRealSubs() {
    local match=

	match=$(subotage_checkFormatMicrodvd_SO "$NAPISUBS/1_microdvd.txt")
	assertEquals "checking the first line and fps from real file" \
        "microdvd 1 23.976" "$match"

	match=$(subotage_checkFormatMicrodvd_SO "$NAPISUBS/2_microdvd.txt")
	assertEquals "checking the first line" \
        "microdvd 1" "$match"

	match=$(subotage_checkFormatMicrodvd_SO "$NAPISUBS/3_microdvd.txt")
	assertEquals "checking the first line" \
        "microdvd 1 23.976" "$match"

	# try with other formats to make sure it doesn't catch any
	match=$(subotage_checkFormatMicrodvd_SO "$NAPISUBS/2_newline_subrip.txt")
	assertEquals "checking subrip no detection" \
        "not_detected" "$match"

	match=$(subotage_checkFormatMicrodvd_SO "$NAPISUBS/1_tmplayer.txt")
	assertEquals "checking tmplayer no detection" \
        "not_detected" "$match"

	match=$(subotage_checkFormatMicrodvd_SO "$NAPISUBS/1_subviewer2.sub")
	assertEquals "checking subviewer2 no detection" \
        "not_detected" "$match"

	match=$(subotage_checkFormatMicrodvd_SO "$NAPISUBS/1_mpl2.txt")
	assertEquals "checking mpl2 no detection" \
        "not_detected" "$match"
}

test_subotage_checkFormatMpl2_SO_withFakeSubs() {
    local subsFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local match=

    {
        echo "junk"
        echo "[123][456]first line"
        echo "[123][456]second line"
    } > "$subsFile"

	match=$(subotage_checkFormatMpl2_SO "$subsFile")
	assertEquals "checking the first line" \
        "mpl2 2" "$match"

    {
        echo "junk"
        echo "junk"
        echo "junk"
        echo "junk"
    } > "$subsFile"

	match=$(subotage_checkFormatMpl2_SO "$subsFile")
	assertEquals "checking negative results for junk file" \
        "not_detected" "$match"
}

test_subotage_checkFormatMpl2_SO_withRealSubs() {
	match=$(subotage_checkFormatMpl2_SO "$NAPISUBS/1_mpl2.txt")
	assertEquals "checking the first line and fps from real file" \
        "mpl2 1" "$match"

	match=$(subotage_checkFormatMpl2_SO "$NAPISUBS/2_mpl2.txt")
	assertEquals "checking the first line 2_mpl2.txt" \
        "mpl2 1" "$match"

	# try with other formats to make sure it doesn't catch any
	match=$(subotage_checkFormatMpl2_SO "$NAPISUBS/2_newline_subrip.txt")
	assertEquals "checking subrip no detection" \
        "not_detected" "$match"

	match=$(subotage_checkFormatMpl2_SO "$NAPISUBS/1_tmplayer.txt")
	assertEquals "checking tmplayer no detection" \
        "not_detected" "$match"

	match=$(subotage_checkFormatMpl2_SO "$NAPISUBS/1_subviewer2.sub")
	assertEquals "checking subviewer2 no detection" \
        "not_detected" "$match"

	match=$(subotage_checkFormatMpl2_SO "$NAPISUBS/1_microdvd.txt")
	assertEquals "checking microdvd no detection" \
        "not_detected" "$match"
}

test_subotage_checkFormatSubrip_SO_withFakeSubs() {
    local subsFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local match=

    {
        echo "junk"
        echo "junk"
        echo "1 00:00:02,123 --> 00:00:12,234"
        echo "some subs line"
    } > "$subsFile"

	match=$(subotage_checkFormatSubrip_SO "$subsFile")
	assertEquals "checking the first line" \
        "subrip 3 inline" "$match"

    {
        echo "junk"
        echo "junk"
        echo "junk"
        echo "junk"
    } > "$subsFile"

	match=$(subotage_checkFormatSubrip_SO "$subsFile")
	assertEquals "check not detecting junk" \
        "not_detected" "$match"
}

test_subotage_checkFormatSubrip_SO_withRealSubs() {
    local match=

    match=$(subotage_checkFormatSubrip_SO "$NAPISUBS/1_inline_subrip.txt")
    assertEquals "checking the first line from real file" \
        "subrip 1 inline" "$match"

    match=$(subotage_checkFormatSubrip_SO "$NAPISUBS/2_newline_subrip.txt")
    assertEquals "checking the first line (newline)" \
        "subrip 1 newline" "$match"

    match=$(subotage_checkFormatSubrip_SO "$NAPISUBS/3_subrip.txt")
    assertEquals "checking the first line (newline)" \
        "subrip 5 newline" "$match"

    # try with other formats to make sure it doesn't catch any
    match=$(subotage_checkFormatSubrip_SO "$NAPISUBS/1_microdvd.txt")
    assertEquals "checking microdvd no detection" \
        "not_detected" "$match"

    match=$(subotage_checkFormatSubrip_SO "$NAPISUBS/1_tmplayer.txt")
    assertEquals "checking tmplayer no detection" \
        "not_detected" "$match"

    match=$(subotage_checkFormatSubrip_SO "$NAPISUBS/1_subviewer2.sub")
    assertEquals "checking subviewer2 no detection" \
        "not_detected" "$match"

    match=$(subotage_checkFormatSubrip_SO "$NAPISUBS/1_mpl2.txt")
    assertEquals "checking mpl2 no detection" \
        "not_detected" "$match"
}

test_subotage_checkFormatSubviewer2_SO_withFakeSubs() {
    local subsFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local match=

    {
        echo "junk"
        echo "junk"
        echo "00:00:02.123,00:00:12.234"
        echo "some subs line"
    } > "$subsFile"

 	match=$(subotage_checkFormatSubviewer2 "$subsFile")
 	assertEquals "checking the first line" "subviewer2 3 0" "$match"

    {
        echo "junk"
        echo "junk"
        echo "junk"
        echo "junk"
    } > "$subsFile"

 	match=$(subotage_checkFormatSubviewer2 "$subsFile")
 	assertEquals "check not detecting junk" "not_detected" "$match"

}

test_subotage_checkFormatSubviewer2_SO_withRealSubs() {
    local match=
	match=$(subotage_checkFormatSubviewer2 "$NAPISUBS/1_subviewer2.sub")
	assertEquals "checking the first line from real file" \
        "subviewer2 11 1" "$match"

	# try with other formats to make sure it doesn't catch any
	match=$(subotage_checkFormatSubviewer2 "$NAPISUBS/1_microdvd.txt")
	assertEquals "checking microdvd no detection" \
        "not_detected" "$match"

	match=$(subotage_checkFormatSubviewer2 "$NAPISUBS/1_tmplayer.txt")
	assertEquals "checking tmplayer no detection" \
        "not_detected" "$match"

	match=$(subotage_checkFormatSubviewer2 "$NAPISUBS/1_inline_subrip.txt")
	assertEquals "checking subrip no detection" \
        "not_detected" "$match"

	match=$(subotage_checkFormatSubviewer2 "$NAPISUBS/2_newline_subrip.txt")
	assertEquals "checking subrip newline no detection" \
        "not_detected" "$match"

	match=$(subotage_checkFormatSubviewer2 "$NAPISUBS/1_mpl2.txt")
	assertEquals "checking mpl2 no detection" \
        "not_detected" "$match"
}

test_subotage_checkFormatTmplayer_SO_withFakeSubs() {
    local subsFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local match=

    {
        echo "junk"
        echo "junk"
        echo "00:00:02=line of subs"
        echo "00:02:02=line of subs"
    } > "$subsFile"

	match=$(subotage_checkFormatTmplayer_SO "$subsFile")
	assertEquals "checking the first line" \
        "tmplayer 3 2 0 =" "$match"

    {
        echo "junk"
        echo "junk"
        echo "0:00:02:line of subs"
        echo "0:02:02:line of subs"
    } > "$subsFile"

	match=$(subotage_checkFormatTmplayer_SO "$subsFile")
	assertEquals "checking the first line" \
        "tmplayer 3 1 0 :" "$match"

    {
        echo "junk"
        echo "junk"
        echo "junk"
        echo "junk"
    } > "$subsFile"

	match=$(subotage_checkFormatTmplayer_SO "$subsFile")
	assertEquals "check not detecting junk" \
        "not_detected" "$match"
}

test_subotage_checkFormatTmplayer_SO_withRealSubs() {
    local match=

    match=$(subotage_checkFormatTmplayer_SO "$NAPISUBS/1_tmplayer.txt")
	assertEquals "checking the first line from real file" \
        "tmplayer 1 2 0 :" "$match"

	match=$(subotage_checkFormatTmplayer_SO "$NAPISUBS/2_tmplayer.txt")
	assertEquals "checking the first line from real file" \
        "tmplayer 1 1 0 :" "$match"

	match=$(subotage_checkFormatTmplayer_SO "$NAPISUBS/3_tmplayer.txt")
	assertEquals "checking the first line from real file" \
        "tmplayer 1 2 1 :" "$match"

	match=$(subotage_checkFormatTmplayer_SO "$NAPISUBS/4_tmplayer.txt")
	assertEquals "checking the first line from real file" \
        "tmplayer 1 2 1 =" "$match"

	# # try with other formats to make sure it doesn't catch any
	match=$(subotage_checkFormatTmplayer_SO "$NAPISUBS/1_microdvd.txt")
	assertEquals "checking microdvd no detection" \
        "not_detected" "$match"

	match=$(subotage_checkFormatTmplayer_SO "$NAPISUBS/1_inline_subrip.txt")
	assertEquals "checking subrip no detection" \
        "not_detected" "$match"

	match=$(subotage_checkFormatTmplayer_SO "$NAPISUBS/1_mpl2.txt")
	assertEquals "checking mpl2 no detection" \
        "not_detected" "$match"

	# not checking subviewer2 and newline subrip
	# because I know that this detector conflict with those
	# that's why it is being placed as last
}

# shunit call
. shunit2
