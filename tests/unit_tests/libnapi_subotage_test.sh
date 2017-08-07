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
. ../../libs/libnapi_fs.sh
. ../../libs/libnapi_retvals.sh
. ../../libs/libnapi_tools.sh
. ../../libs/libnapi_wrappers.sh

# fakes/mocks
. fake/libnapi_logging_fake.sh
. mock/scpmocker.sh

# module under test
. ../../libs/libnapi_subotage.sh

oneTimeSetUp() {
    fs_configure_GV
    subotage_configure_GV
}

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

 	match=$(subotage_checkFormatSubviewer2_SO "$subsFile")
 	assertEquals "checking the first line" "subviewer2 3 0" "$match"

    {
        echo "junk"
        echo "junk"
        echo "junk"
        echo "junk"
    } > "$subsFile"

 	match=$(subotage_checkFormatSubviewer2_SO "$subsFile")
 	assertEquals "check not detecting junk" "not_detected" "$match"

}

test_subotage_checkFormatSubviewer2_SO_withRealSubs() {
    local match=
	match=$(subotage_checkFormatSubviewer2_SO "$NAPISUBS/1_subviewer2.sub")
	assertEquals "checking the first line from real file" \
        "subviewer2 11 1" "$match"

	# try with other formats to make sure it doesn't catch any
	match=$(subotage_checkFormatSubviewer2_SO "$NAPISUBS/1_microdvd.txt")
	assertEquals "checking microdvd no detection" \
        "not_detected" "$match"

	match=$(subotage_checkFormatSubviewer2_SO "$NAPISUBS/1_tmplayer.txt")
	assertEquals "checking tmplayer no detection" \
        "not_detected" "$match"

	match=$(subotage_checkFormatSubviewer2_SO "$NAPISUBS/1_inline_subrip.txt")
	assertEquals "checking subrip no detection" \
        "not_detected" "$match"

	match=$(subotage_checkFormatSubviewer2_SO "$NAPISUBS/2_newline_subrip.txt")
	assertEquals "checking subrip newline no detection" \
        "not_detected" "$match"

	match=$(subotage_checkFormatSubviewer2_SO "$NAPISUBS/1_mpl2.txt")
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

test_subotage_readFormatSubviewer2_withFakeSubs() {
    local subsFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local outputFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local data=
    local adata=()

    {
        echo "00:00:02.123,00:00:12.234"
        echo "some subs line"
        echo ""
        echo "00:00:03.123,00:00:10.234"
        echo "some subs line2"
    } > "$subsFile"

    subotage_readFormatSubviewer2 \
        "$subsFile" "$outputFile" "subviewer2 1 0"

	data=$(sed -n 1p "$outputFile")
	assertEquals 'check for file type' \
        "secs" "$data"

	data=$(sed -n 2p "$outputFile")
	adata=( $data )

	assertEquals 'check counter' 1 "${adata[0]}"
	assertEquals 'check start_time' "2.123" "${adata[1]}"
	assertEquals 'check end_time' "12.234" "${adata[2]}"
	assertEquals 'check content' "some" "${adata[3]}"
}

test_subotage_readFormatSubviewer2_withRealSubs() {
    local outputFile=$(mktemp -p "${SHUNIT_TMPDIR}")

    subotage_readFormatSubviewer2 \
        "$NAPISUBS/1_subviewer2.sub" "$outputFile" "subviewer2 11 1"

	data=$(sed -n 2p "$outputFile")
	adata=( $data )

	assertEquals 'check counter' 1 "${adata[0]}"
	assertEquals 'check start_time' "60.1" "${adata[1]}"
	assertEquals 'check end_time' "120.2" "${adata[2]}"
	assertEquals 'check content' "Oh," "${adata[3]}"
}

test_subotage_readFormatTmplayer_withFakeSubs() {
    local subsFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local outputFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local data=
    local adata=()

    {
        echo "00:10:12=line1"
        echo "00:10:20=line2"
    } > "$subsFile"

    subotage_readFormatTmplayer \
        "$subsFile" "$outputFile" "tmplayer 1 2 0 ="

	data=$(sed -n 1p "$outputFile")
	assertEquals 'check for file type' \
        "hms" "$data"

	data=$(sed -n 2p "$outputFile")
	adata=( $data )

	assertEquals 'check counter' 1 "${adata[0]}"
	assertEquals 'check start_time' "00:10:12" "${adata[1]}"
	assertEquals 'check end_time' "00:10:15" "${adata[2]}"
	assertEquals 'check content' "line1" "${adata[3]}"
}

test_subotage_readFormatTmplayer_withRealSubs() {
    local outputFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local idx=1
    local i=

	declare -a fileDetails=( "tmplayer 1 2 0 :" \
		"tmplayer 1 1 0 :" \
		"tmplayer 1 2 1 :" \
		"tmplayer 1 2 1 =" )

	# now let's try with real files
	for i in "${fileDetails[@]}"; do
		subotage_readFormatTmplayer \
            "$NAPISUBS/${idx}_tmplayer.txt" "$outputFile" "$i"

        data=$(sed -n 2p "$outputFile")
		adata=( $data )

		assertEquals 'check counter' 1 "${adata[0]}"
		assertEquals 'check start_time' "00:03:46" "${adata[1]}"
		assertEquals 'check end_time' "00:03:49" "${adata[2]}"
		assertEquals 'check content' "Nic.|Od" "${adata[3]}"
		idx=$(( idx + 1 ))
	done
}

test_subotage_readFormatMicrodvd_withFakeSubs() {
    local subsFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local outputFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local data=
    local adata=()

    {
        echo "{100}{200}line1"
        echo "{100}{200}line2"
    } > "$subsFile"

    subotage_readFormatMicrodvd \
        "$subsFile" "$outputFile" "microdvd 1" 25

    data=$(sed -n 1p "$outputFile")
	assertEquals 'check for file type' "secs" "$data"

    data=$(sed -n 2p "$outputFile")
	adata=( $data )
	assertEquals 'check counter' 1 "${adata[0]}"
	assertEquals 'check start_time' "4" "${adata[1]}"
	assertEquals 'check end_time' "8" "${adata[2]}"
	assertEquals 'check content' "line1" "${adata[3]}"
}

test_subotage_readFormatMicrodvd_withRealSubs() {
    local outputFile=$(mktemp -p "${SHUNIT_TMPDIR}")

	local fileStarts=( "padding" \
		"1" \
		"1219" \
		"1" )

	local fileEnds=( "padding" \
		"1" \
		"1421" \
		"72" )

	local fileData=( "padding" \
		"23.976" \
		"prawie" \
		"movie" )

    local details="microdvd 1"
    local i=

	# now let's try with real files
	for i in {1..3}; do
		subotage_readFormatMicrodvd \
           "$NAPISUBS/${i}_microdvd.txt" "$outputFile" "$details" 1

		data=$(sed -n 2p "$outputFile" | wrappers_stripNewLine_SO)
		adata=( $data )
		assertEquals 'check counter' 1 "${adata[0]}"
		assertEquals 'check start_time' "${fileStarts[$i]}" "${adata[1]}"
		assertEquals 'check end_time' "${fileEnds[$i]}" "${adata[2]}"
		assertEquals 'check content' "${fileData[$i]}" "${adata[3]}"
	done
}

test_subotage_readFormatMpl2_withFakeSubs() {
    local subsFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local outputFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local data=
    local adata=()

    {
        echo "[100][200]line1"
        echo "[100][200]line2"
    } > "$subsFile"

    subotage_readFormatMpl2 \
        "$subsFile" "$outputFile" "mpl2 1"

    data=$(sed -n 1p "$outputFile")
	assertEquals 'check for file type' "secs" "$data"

    data=$(sed -n 2p "$outputFile")
	adata=( $data )
	assertEquals 'check counter' 1 "${adata[0]}"
	assertEquals 'check start_time' "10" "${adata[1]}"
	assertEquals 'check end_time' "20" "${adata[2]}"
	assertEquals 'check content' "line1" "${adata[3]}"
}

test_subotage_readFormatMpl2_withRealSubs() {
    local outputFile=$(mktemp -p "${SHUNIT_TMPDIR}")
	declare -a fileStarts=( "padding" \
		"100" \
		"46.1" )

	declare -a fileEnds=( "padding" \
		"104.8" \
		"51" )

	declare -a fileData=( "padding" \
		"Aktualny" \
		"/Zaledwie" )

	# now let's try with real files
	for i in {1..2}; do
		subotage_readFormatMpl2 \
            "$NAPISUBS/${i}_mpl2.txt" "$outputFile" "mpl2 1"

        data=$(sed -n 2p "$outputFile" | wrappers_stripNewLine_SO)
		adata=( $data )

		assertEquals 'check counter' 1 "${adata[0]}"
		assertEquals 'check start_time' "${fileStarts[$i]}" "${adata[1]}"
		assertEquals 'check end_time' "${fileEnds[$i]}" "${adata[2]}"
		assertEquals 'check content' "${fileData[$i]}" "${adata[3]}"
	done
}

test_subotage_readFormatSubrip_withFakeSubs() {
    local subsFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local outputFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local data=
    local adata=()

    {
        echo "1 00:00:02,123 --> 00:00:12,234"
        echo "some subs line"
    } > "$subsFile"

    subotage_readFormatSubrip \
        "$subsFile" "$outputFile" "subrip 1 inline"

    data=$(sed -n 1p "$outputFile")
	assertEquals 'check for file type' "hmsms" "$data"

    data=$(sed -n 2p "$outputFile")
	adata=( $data )

	assertEquals 'check counter' 1 "${adata[0]}"
	assertEquals 'check start_time' "00:00:02.123" "${adata[1]}"
	assertEquals 'check end_time' "00:00:12.234" "${adata[2]}"
	assertEquals 'check content' "some" "${adata[3]}"
}

test_subotage_readFormatSubrip_withRealSubs() {
    local outputFile=$(mktemp -p "${SHUNIT_TMPDIR}")

	subotage_readFormatSubrip \
        "${NAPISUBS}/1_inline_subrip.txt" "$outputFile" "subrip 1 inline"

    data=$(sed -n 2p "$outputFile" | wrappers_stripNewLine_SO)
	adata=( $data )
	assertEquals 'inline check counter' 1 "${adata[0]}"
	assertEquals 'inline check start_time' "00:00:49.216" "${adata[1]}"
	assertEquals 'inline check end_time' "00:00:53.720" "${adata[2]}"
	assertEquals 'inline check content' "Panie" "${adata[3]}"

	subotage_readFormatSubrip \
        "$NAPISUBS/2_newline_subrip.txt" "$outputFile" "subrip 1 newline"

    data=$(sed -n 2p "$outputFile" | wrappers_stripNewLine_SO)
	adata=( $data )
	assertEquals 'newline check counter' 1 "${adata[0]}"
	assertEquals 'newline check start_time' "00:00:49.216" "${adata[1]}"
	assertEquals 'newline check end_time' "00:00:53.720" "${adata[2]}"
	assertEquals 'newline check content' "Panie" "${adata[3]}"

	subotage_readFormatSubrip \
        "$NAPISUBS/3_subrip.txt" "$outputFile" "subrip 5 newline"

    data=$(sed -n 2p "$outputFile" | wrappers_stripNewLine_SO)
	adata=( $data )
	assertEquals 'offset check counter' 1 "${adata[0]}"
	assertEquals 'offset check start_time' "00:00:56.556" "${adata[1]}"
	assertEquals 'offset check end_time' "00:01:02.062" "${adata[2]}"
	assertEquals 'offset check content' "Pod" "${adata[3]}"
}

test_subotage_writeFormatMicrodvd() {
    local uniFormatFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local outputFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local status=
    local data=

    {
        echo "junk"
        echo "junk"
        echo "junk"
    } > "$uniFormatFile"

    subotage_writeFormatMicrodvd \
        "$uniFormatFile" "$outputFile" "" "25"
    status=$?

	assertNotEquals "checking return value for junk in uni format" \
        "$G_RETOK" "$status"

    {
        echo "secs"
        echo "1 10 20 line1"
        echo "2 22 25 line2"
    } > "$uniFormatFile"

    subotage_writeFormatMicrodvd \
        "$uniFormatFile" "$outputFile" "" "25"
    status=$?

	assertEquals "checking return value for correct uni format" \
        "$G_RETOK" "$status"

    data=$(sed -n 1p "$outputFile" | \
        wrappers_stripNewLine_SO | \
        grep -c "{250}{500}line1")
	assertTrue "checking output 1" \
        "[ \"$data\" -ge 1 ]"

	data=$(sed -n 2p "$outputFile" | \
        wrappers_stripNewLine_SO | \
        grep -c "{550}{625}line2")
	assertTrue "checking output 2" \
        "[ \"$data\" -ge 1 ]"

    {
        echo "hms"
        echo "1 00:00:10 00:00:20 line1"
        echo "2 00:00:22 00:00:25 line2"
    } > "$uniFormatFile"

    subotage_writeFormatMicrodvd \
        "$uniFormatFile" "$outputFile" "" "25"
    status=$?

	assertEquals "checking return value for hms uni" \
        "$G_RETOK" "$status"

	data=$(sed -n 1p "$outputFile" | \
        wrappers_stripNewLine_SO | \
        grep -c "{250}{500}line1")
	assertTrue "checking output 3" \
        "[ \"$data\" -ge 1 ]"

	data=$(sed -n 2p "$outputFile" | \
        wrappers_stripNewLine_SO | \
        grep -c "{550}{625}line2")
	assertTrue "checking output 4" \
        "[ \"$data\" -ge 1 ]"

    {
        echo "hmsms"
        echo "1 00:00:10.5 00:00:20.5 line1"
        echo "2 00:00:22.5 00:00:25.5 line2"
    } > "$uniFormatFile"

    subotage_writeFormatMicrodvd \
        "$uniFormatFile" "$outputFile" "" "30"
    status=$?
	assertEquals "checking return value for hmsms 30" \
        "$G_RETOK" "$status"

	data=$(sed -n 1p "$outputFile" | \
       wrappers_stripNewLine_SO | \
       grep -c "{315}{615}line1")
	assertTrue "checking output 5" \
        "[ \"$data\" -ge 1 ]"

	data=$(sed -n 2p "$outputFile" | \
        wrappers_stripNewLine_SO | \
        grep -c "{675}{765}line2")
	assertTrue "checking output 6" \
        "[ \"$data\" -ge 1 ]"
}

test_subotage_writeFormatMpl2() {
    local uniFormatFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local outputFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local status=
    local data=

    {
        echo "junk"
        echo "junk"
        echo "junk"
    } > "$uniFormatFile"

    subotage_writeFormatMpl2 \
        "$uniFormatFile" "$outputFile" "" ""
    status=$?

	assertNotEquals "checking return value for junk in uni format" \
        "$G_RETOK" "$status"

    {
        echo "secs"
        echo "1 10 20 line1"
        echo "2 22 25 line2"
    } > "$uniFormatFile"

    subotage_writeFormatMpl2 \
        "$uniFormatFile" "$outputFile" "" "25"
    status=$?

	assertEquals "checking return value for correct uni format" \
        "$G_RETOK" "$status"

    data=$(sed -n 1p "$outputFile" | \
        wrappers_stripNewLine_SO | \
        grep -c "\[100\]\[200\]line1")
	assertTrue "checking output 1" \
        "[ \"$data\" -ge 1 ]"

	data=$(sed -n 2p "$outputFile" | \
        wrappers_stripNewLine_SO | \
        grep -c "\[220\]\[250\]line2")
	assertTrue "checking output 2" \
        "[ \"$data\" -ge 1 ]"

    {
        echo "hms"
        echo "1 00:00:10 00:00:20 line1"
        echo "2 00:00:22 00:00:25 line2"
    } > "$uniFormatFile"

    subotage_writeFormatMpl2 \
        "$uniFormatFile" "$outputFile" "" ""
    status=$?

	assertEquals "checking return value for hms uni" \
        "$G_RETOK" "$status"

	data=$(sed -n 1p "$outputFile" | \
        wrappers_stripNewLine_SO | \
        grep -c "\[100\]\[200\]line1")
	assertTrue "checking output 3" \
        "[ \"$data\" -ge 1 ]"

	data=$(sed -n 2p "$outputFile" | \
        wrappers_stripNewLine_SO | \
        grep -c "\[220\]\[250\]line2")
	assertTrue "checking output 4" \
        "[ \"$data\" -ge 1 ]"

    {
        echo "hmsms"
        echo "1 00:00:10.5 00:00:20.5 line1"
        echo "2 00:00:22.5 00:00:25.5 line2"
    } > "$uniFormatFile"

    subotage_writeFormatMpl2 \
        "$uniFormatFile" "$outputFile" "" ""
    status=$?

	assertEquals "checking return value for hmsms" \
        "$G_RETOK" "$status"

	data=$(sed -n 1p "$outputFile" | \
       wrappers_stripNewLine_SO | \
       grep -c "\[105\]\[205\]line1")
	assertTrue "checking output 5" \
        "[ \"$data\" -ge 1 ]"

	data=$(sed -n 2p "$outputFile" | \
        wrappers_stripNewLine_SO | \
        grep -c "\[225\]\[255\]line2")
	assertTrue "checking output 6" \
        "[ \"$data\" -ge 1 ]"
}

test_subotage_writeFormatTmplayer() {
    local uniFormatFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local outputFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local status=
    local data=

    {
        echo "junk"
        echo "junk"
        echo "junk"
    } > "$uniFormatFile"

    subotage_writeFormatTmplayer \
        "$uniFormatFile" "$outputFile" "" ""
    status=$?

	assertNotEquals "checking return value for junk in uni format" \
        "$G_RETOK" "$status"

    {
        echo "secs"
        echo "1 10 20 line1"
        echo "2 22 25 line2"
    } > "$uniFormatFile"

    subotage_writeFormatTmplayer \
        "$uniFormatFile" "$outputFile" "" ""
    status=$?

	assertEquals "checking return value for correct uni format" \
        "$G_RETOK" "$status"

    data=$(sed -n 1p "$outputFile" | \
        wrappers_stripNewLine_SO | \
        grep -c "00:00:10:line1")
	assertTrue "checking output 1" \
        "[ \"$data\" -ge 1 ]"

	data=$(sed -n 2p "$outputFile" | \
        wrappers_stripNewLine_SO | \
        grep -c "00:00:22:line2")
	assertTrue "checking output 2" \
        "[ \"$data\" -ge 1 ]"

    {
        echo "hms"
        echo "1 00:00:10 00:00:20 line1"
        echo "2 00:00:22 00:00:25 line2"
    } > "$uniFormatFile"

    subotage_writeFormatTmplayer \
        "$uniFormatFile" "$outputFile" "" ""
    status=$?

	assertEquals "checking return value for hms uni" \
        "$G_RETOK" "$status"

	data=$(sed -n 1p "$outputFile" | \
        wrappers_stripNewLine_SO | \
        grep -c "00:00:10:line1")
	assertTrue "checking output 3" \
        "[ \"$data\" -ge 1 ]"

	data=$(sed -n 2p "$outputFile" | \
        wrappers_stripNewLine_SO | \
        grep -c "00:00:22:line2")
	assertTrue "checking output 4" \
        "[ \"$data\" -ge 1 ]"

    {
        echo "hmsms"
        echo "1 00:00:10.5 00:00:20.5 line1"
        echo "2 00:00:22.5 00:00:25.5 line2"
    } > "$uniFormatFile"

    subotage_writeFormatTmplayer \
        "$uniFormatFile" "$outputFile" "" ""
    status=$?

	assertEquals "checking return value for hmsms" \
        "$G_RETOK" "$status"

	data=$(sed -n 1p "$outputFile" | \
       wrappers_stripNewLine_SO | \
       grep -c "00:00:10:line1")
	assertTrue "checking output 5" \
        "[ \"$data\" -ge 1 ]"

	data=$(sed -n 2p "$outputFile" | \
        wrappers_stripNewLine_SO | \
        grep -c "00:00:22:line2")
	assertTrue "checking output 6" \
        "[ \"$data\" -ge 1 ]"
}

test_subotage_writeFormatSubviewer2() {
    local uniFormatFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local outputFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local status=
    local data=

    {
        echo "junk"
        echo "junk"
        echo "junk"
    } > "$uniFormatFile"

    subotage_writeFormatSubviewer2 \
        "$uniFormatFile" "$outputFile" "" ""
    status=$?

	assertNotEquals "checking return value for junk in uni format" \
        "$G_RETOK" "$status"

    {
        echo "secs"
        echo "1 10 20 line1"
        echo "2 22 25 line2"
    } > "$uniFormatFile"

    subotage_writeFormatSubviewer2 \
        "$uniFormatFile" "$outputFile" "" ""
    status=$?

	assertEquals "checking return value for correct uni format" \
        "$G_RETOK" "$status"

    data=$(sed -n 11p "$outputFile" | \
        wrappers_stripNewLine_SO | \
        grep -c "00:00:10\.00,00:00:20\.00")
	assertTrue "checking output 1" \
        "[ \"$data\" -ge 1 ]"

	data=$(sed -n 14p "$outputFile" | \
        wrappers_stripNewLine_SO | \
        grep -c "00:00:22\.00,00:00:25\.00")
	assertTrue "checking output 2" \
        "[ \"$data\" -ge 1 ]"

    {
        echo "hms"
        echo "1 00:00:10 00:00:20 line1"
        echo "2 00:00:22 00:00:25 line2"
    } > "$uniFormatFile"

    subotage_writeFormatSubviewer2 \
        "$uniFormatFile" "$outputFile" "" ""
    status=$?

	assertEquals "checking return value for hms uni" \
        "$G_RETOK" "$status"

	data=$(sed -n 11p "$outputFile" | \
        wrappers_stripNewLine_SO | \
        grep -c "00:00:10\.00,00:00:20\.00")
	assertTrue "checking output 3" \
        "[ \"$data\" -ge 1 ]"

	data=$(sed -n 14p "$outputFile" | \
        wrappers_stripNewLine_SO | \
        grep -c "00:00:22\.00,00:00:25\.00")
	assertTrue "checking output 4" \
        "[ \"$data\" -ge 1 ]"

    {
        echo "hmsms"
        echo "1 00:00:10.5 00:00:20.5 line1"
        echo "2 00:00:22.5 00:00:25.5 line2"
    } > "$uniFormatFile"

    subotage_writeFormatSubviewer2 \
        "$uniFormatFile" "$outputFile" "" ""
    status=$?

	assertEquals "checking return value for hmsms" \
        "$G_RETOK" "$status"

	data=$(sed -n 11p "$outputFile" | \
       wrappers_stripNewLine_SO | \
       grep -c "00:00:10\.50,00:00:20\.50")
	assertTrue "checking output 5" \
        "[ \"$data\" -ge 1 ]"

	data=$(sed -n 14p "$outputFile" | \
        wrappers_stripNewLine_SO | \
        grep -c "00:00:22\.50,00:00:25\.50")
	assertTrue "checking output 6" \
        "[ \"$data\" -ge 1 ]"
}

test_subotage_writeFormatSubrip() {
    local uniFormatFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local outputFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local status=
    local data=

    {
        echo "junk"
        echo "junk"
        echo "junk"
    } > "$uniFormatFile"

    subotage_writeFormatSubrip \
        "$uniFormatFile" "$outputFile" "" ""
    status=$?

	assertNotEquals "checking return value for junk in uni format" \
        "$G_RETOK" "$status"

    {
        echo "secs"
        echo "1 10 20 line1"
        echo "2 22 25 line2"
    } > "$uniFormatFile"

    subotage_writeFormatSubrip \
        "$uniFormatFile" "$outputFile" "" ""
    status=$?

	assertEquals "checking return value for correct uni format" \
        "$G_RETOK" "$status"

    data=$(sed -n 1p "$outputFile" | wrappers_stripNewLine_SO)
	assertEquals "subrip checking output 1" \
        1 "$data"

	data=$(sed -n 2p "$outputFile" | \
        wrappers_stripNewLine_SO | \
        grep -c "00:00:10,000 --> 00:00:20,000")
	assertTrue "subrip checking output 2" \
        "[ \"$data\" -ge 1 ]"

	data=$(sed -n 3p "$outputFile" | \
        wrappers_stripNewLine_SO | \
        grep -c "line1")
	assertTrue "subrip checking output 3" \
        "[ \"$data\" -ge 1 ]"

    {
        echo "hms"
        echo "1 00:00:10 00:00:20 line1"
        echo "2 00:00:22 00:00:25 line2"
    } > "$uniFormatFile"

    subotage_writeFormatSubrip \
        "$uniFormatFile" "$outputFile" "" ""
    status=$?

	assertEquals "subrip checking return value for format hms" \
        "$G_RETOK" "$status"

    data=$(sed -n 1p "$outputFile" | wrappers_stripNewLine_SO)
	assertEquals "subrip checking output 4" \
        1 "$data"

	data=$(sed -n 2p "$outputFile" | \
        wrappers_stripNewLine_SO | \
        grep -c "00:00:10,000 --> 00:00:20,000")
	assertTrue "subrip checking output 5" \
        "[ \"$data\" -ge 1 ]"

	data=$(sed -n 3p "$outputFile" | \
        wrappers_stripNewLine_SO | \
        grep -c "line1")
	assertTrue "subrip checking output 6" \
        "[ \"$data\" -ge 1 ]"

    {
        echo "hmsms"
        echo "1 00:00:10.5 00:00:20.5 line1"
        echo "2 00:00:22.5 00:00:25.5 line2"
    } > "$uniFormatFile"

    subotage_writeFormatSubrip \
        "$uniFormatFile" "$outputFile" "" ""
    status=$?

	assertEquals "subrip checking return value for format hmsms" \
        "$G_RETOK" "$status"

    data=$(sed -n 1p "$outputFile" | wrappers_stripNewLine_SO)
	assertEquals "subrip checking output 7" \
        1 "$data"

	data=$(sed -n 2p "$outputFile" | \
        wrappers_stripNewLine_SO | \
        grep -c "00:00:10,500 --> 00:00:20,500")
	assertTrue "subrip checking output 8" \
        "[ \"$data\" -ge 1 ]"

	data=$(sed -n 3p "$outputFile" | \
        wrappers_stripNewLine_SO | \
        grep -c "line1")
	assertTrue "subrip checking output 9" \
        "[ \"$data\" -ge 1 ]"
}

test_subotage_guessFormat() {
	local files=( "1_inline_subrip.txt" \
		"1_microdvd.txt" \
		"1_mpl2.txt" \
		"1_subviewer2.sub" \
		"1_tmplayer.txt" \
		"2_microdvd.txt" \
		"2_mpl2.txt" \
		"2_newline_subrip.txt" \
		"2_tmplayer.txt" \
		"3_microdvd.txt" \
		"3_subrip.txt" \
		"3_tmplayer.txt" \
		"4_tmplayer.txt" )

	local formats=( "subrip 1 inline" \
		"microdvd 1 23.976" \
		"mpl2 1" \
		"subviewer2 11 1" \
		"tmplayer 1 2 0 :" \
		"microdvd 1" \
		"mpl2 1" \
		"subrip 1 newline" \
		"tmplayer 1 1 0 :" \
		"microdvd 1 23.976" \
		"subrip 5 newline" \
		"tmplayer 1 2 1 :" \
		"tmplayer 1 2 1 =" )

	local idx=0
    local i=0
	local status=0
	local path=
	local format=

	for i in "${files[@]}"; do
		path="$NAPISUBS/$i"
		format=$(subotage_guessFormat "$path")
		status=$?
		assertEquals "checking exit code for $i" $G_RETOK "$status"
		assertEquals "checking details for $i" "${formats[$idx]}" "$format"
		idx=$(( idx + 1 ))
	done
}

test_subotage_correctOverlaps() {
    local tmp=$(mktemp -p "${SHUNIT_TMPDIR}")
	local status=0
	local data=
	local adata=()

    # should reject unsupported format
    {
        echo "xxx"
        echo "junk"
    } > "$tmp"
	subotage_correctOverlaps "$tmp"
	status=$?
	assertEquals "xxx not supported" $G_RETNOACT "$status"

    {
        echo "hms"
        echo "1 00:05:56 00:05:59 Zmierzasz na"
        echo "2 00:05:58 00:06:01 Polnoc."
        echo "3 00:06:00 00:06:03 Wskakuj"
        echo "4 00:06:02 00:06:05 Upewnie sie, | ze znajdziesz droge"
        echo "5 00:06:17 00:06:20 - Dokad zmierzasz? | - Portland"
        echo "6 00:06:20 00:06:23 Portland jest na poludniu mowiles, | ze zmierzasz na polnoc"
    } > "$tmp"

	subotage_correctOverlaps "$tmp"
	status=$?
	assertEquals "hms status ok" $G_RETOK "$status"

	data=$(sed -n 1p "$tmp")
    assertEquals 'check for file type (hms)' \
        "hms" "$data"

	data=$(sed -n 2p "$tmp")
	adata=( $data )
    assertEquals '1 (hms) check counter' 1 "${adata[0]}"
	assertEquals '1 (hms) check start_time' "00:05:56" "${adata[1]}"
	assertEquals '1 (hms) check end_time' "00:05:58" "${adata[2]}"
	assertEquals '1 (hms) check content' "Zmierzasz" "${adata[3]}"

	data=$(sed -n 3p "$tmp")
	adata=( $data )
    assertEquals '2 (hms) check counter' 2 "${adata[0]}"
	assertEquals '2 (hms) check start_time' "00:05:58" "${adata[1]}"
	assertEquals '2 (hms) check end_time' "00:06:00" "${adata[2]}"
	assertEquals '2 (hms) check content' "Polnoc." "${adata[3]}"

	data=$(sed -n 4p "$tmp")
	adata=( $data )
    assertEquals '3 (hms) check counter' 3 "${adata[0]}"
	assertEquals '3 (hms) check start_time' "00:06:00" "${adata[1]}"
	assertEquals '3 (hms) check end_time' "00:06:02" "${adata[2]}"
	assertEquals '3 (hms) check content' "Wskakuj" "${adata[3]}"

	data=$(sed -n 5p "$tmp")
	adata=( $data )
    assertEquals '4 (hms) check counter' 4 "${adata[0]}"
	assertEquals '4 (hms) check start_time' "00:06:02" "${adata[1]}"
	assertEquals '4 (hms) check end_time' "00:06:05" "${adata[2]}"
	assertEquals '4 (hms) check content' "Upewnie" "${adata[3]}"
	unlink "$tmp"

    # === hmsms
    {
        echo "hmsms"
        echo "1 00:05:56.000 00:05:59.000 Zmierzasz na polnoc"
        echo "2 00:05:58.000 00:06:01.000 Polnoc."
        echo "3 00:06:00.000 00:06:03.000 Wskakuj"
        echo "4 00:06:02.000 00:06:05.000 Upewnie sie, | ze znajdziesz droge."
    } > "$tmp"

    subotage_correctOverlaps "$tmp"
	status=$?
	assertEquals "hmsms status ok" $G_RETOK "$status"

	data=$(sed -n 1p "$tmp")
    assertEquals 'check for file type (hmsms)' "hmsms" "$data"

	data=$(sed -n 2p "$tmp")
	adata=( $data )
    assertEquals '1 (hmsms) check counter' 1 "${adata[0]}"
	assertEquals '1 (hmsms) check start_time' "00:05:56.000" "${adata[1]}"
	assertEquals '1 (hmsms) check end_time' "00:05:58.000" "${adata[2]}"
	assertEquals '1 (hmsms) check content' "Zmierzasz" "${adata[3]}"

	data=$(sed -n 3p "$tmp")
	adata=( $data )
    assertEquals '2 (hmsms) check counter' 2 "${adata[0]}"
	assertEquals '2 (hmsms) check start_time' "00:05:58.000" "${adata[1]}"
	assertEquals '2 (hmsms) check end_time' "00:06:00.000" "${adata[2]}"
	assertEquals '2 (hmsms) check content' "Polnoc." "${adata[3]}"

	data=$(sed -n 4p "$tmp")
	adata=( $data )
    assertEquals '3 (hmsms) check counter' 3 "${adata[0]}"
	assertEquals '3 (hmsms) check start_time' "00:06:00.000" "${adata[1]}"
	assertEquals '3 (hmsms) check end_time' "00:06:02.000" "${adata[2]}"
	assertEquals '3 (hmsms) check content' "Wskakuj" "${adata[3]}"

	data=$(sed -n 5p "$tmp")
	adata=( $data )
    assertEquals '4 (hmsms) check counter' 4 "${adata[0]}"
	assertEquals '4 (hmsms) check start_time' "00:06:02.000" "${adata[1]}"
	assertEquals '4 (hmsms) check end_time' "00:06:05.000" "${adata[2]}"
	assertEquals '4 (hmsms) check content' "Upewnie" "${adata[3]}"
	unlink "$tmp"

    # === secs
    {
        echo "secs"
        echo "1 10 20 line1"
        echo "2 18 25 overlap1"
        echo "3 23 28 overlap2"
    } > "$tmp"

    subotage_correctOverlaps "$tmp"
	status=$?
	assertEquals "secs status ok" $G_RETOK "$status"

	data=$(sed -n 1p "$tmp")
	assertEquals 'check for file type' "secs" "$data"

	data=$(sed -n 2p "$tmp")
	adata=( $data )
	assertEquals '1 check counter' 1 "${adata[0]}"
	assertEquals '1 check start_time' "10" "${adata[1]}"
	assertEquals '1 check end_time' "18" "${adata[2]}"
	assertEquals '1 check content' "line1" "${adata[3]}"

	data=$(sed -n 3p "$tmp")
	adata=( $data )
	assertEquals '2 check counter' 2 "${adata[0]}"
	assertEquals '2 check start_time' "18" "${adata[1]}"
	assertEquals '2 check end_time' "23" "${adata[2]}"
	assertEquals '2 check content' "overlap1" "${adata[3]}"

	data=$(sed -n 4p "$tmp")
	adata=( $data )
	assertEquals '3 check counter' 3 "${adata[0]}"
	assertEquals '3 check start_time' "23" "${adata[1]}"
	assertEquals '3 check end_time' "28" "${adata[2]}"
	assertEquals '3 check content' "overlap2" "${adata[3]}"
}

test_subotage_detectMicrodvdFps_SO() {
	local status=0

	local data=( "{1}{1}23.976fps" \
	   "{1}{72}movie info: XVID  720x304 23.976fps 1.4 GB" \
	   "{1}{72}movie info: XVID  720x304 25.0 1.4 GB" \
	   "{1}{72}30fps" \
	   "{1}{72}30" )

	local res=( "23.976" \
	   "23.976" \
	   "25.0" \
	   "30" \
	   "30" )

	local idx=0
	local fps=0

	for i in "${data[@]}"; do
		fps=$(echo "$i" | subotage_detectMicrodvdFps_SO)
		assertEquals "checking fps $idx" "${res[$idx]}" "$fps"
		idx=$(( idx + 1 ))
	done
}

test_subotage_isFormatSupported() {
	local status=0
	subotage_isFormatSupported "bogus_format"
	status=$?
	assertEquals "failure for bogus format" $G_RETPARAM "$status"

	local formats=( "subrip" "microdvd" "subviewer2" "mpl2" "tmplayer" )
	for i in "${formats[@]}"; do
		subotage_isFormatSupported "$i"
		status=$?
		assertEquals "$i format" $G_RETOK "$status"
	done
}

test_subotage_isConversionNeeded() {
	local status=0

    subotage_isConversionNeeded \
        "subrip" "0" "" "SUBRIP" "0"
    status="$?"
	assertEquals "conversion not needed rv check" $G_RETNOACT "$status"

    subotage_isConversionNeeded \
        "subrip" "0" "" "mpl2" "0"
    status="$?"
	assertEquals "conversion needed rv check" $G_RETOK "$status"

    subotage_isConversionNeeded \
        "microdvd" "23.456" "" "microdvd" "23.456"
    status="$?"
	assertEquals "conversion not needed udvd same fps" $G_RETNOACT "$status"

    subotage_isConversionNeeded \
        "microdvd" "23.456" "" "microdvd" "23.756"
    status="$?"
	assertEquals "conversion needed udvd != fps" $G_RETOK "$status"
}

test_subotage_convertFormats() {
    local status=0
    local subsFile=$(mktemp -p "${SHUNIT_TMPDIR}")
    local outputFile=$(mktemp -p "${SHUNIT_TMPDIR}")

    scpmocker_patchFunction "test_reader"
    scpmocker_patchFunction "test_writer"
    scpmocker_patchFunction "subotage_correctOverlaps"

    scpmocker -c func_subotage_correctOverlaps program -e $G_RETOK

    # first call
    scpmocker -c func_test_reader program -e $G_RETFAIL

    # second call
    scpmocker -c func_test_reader program -e $G_RETOK
    scpmocker -c func_test_writer program -e $G_RETFAIL

    # third call
    scpmocker -c func_test_reader program -e $G_RETOK
    scpmocker -c func_test_writer program -e $G_RETOK

    subotage_convertFormats \
        "test_reader" "test_writer" "$subsFile" "$outputFile"
    status=$?
    assertEquals "reader/writer failure" $G_RETFAIL "$status"

    subotage_convertFormats \
        "test_reader" "test_writer" "$subsFile" "$outputFile"
    status=$?
    assertEquals "writer failure" $G_RETFAIL "$status"

    subotage_convertFormats \
        "test_reader" "test_writer" "$subsFile" "$outputFile"
    status=$?
    assertEquals "reader/writer success" $G_RETOK "$status"

    scpmocker_resetFunction "subotage_correctOverlaps"
    scpmocker_resetFunction "test_writer"
    scpmocker_resetFunction "test_reader"
}

# shunit call
. shunit2
