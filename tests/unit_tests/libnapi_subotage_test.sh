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

# test_write_format_microdvd() {
# 	local tmp=$(mktemp tmp.XXXXXXXX)
# 	local out=$(mktemp out.XXXXXXXX)
# 	local status=0
# 	local data=''
#
#
# 	echo "junk" > "$tmp"
# 	echo "junk" >> "$tmp"
#
# 	g_outf[$___FPS]=25
# 	write_format_microdvd "$tmp" "$out" >/dev/null 2>&1
# 	status=$?
# 	assertEquals "checking return value" "$RET_FAIL" "$status"
#
# 	echo "secs" > "$tmp"
# 	echo "1 10 20 line1" >> "$tmp"
# 	echo "2 22 25 line2" >> "$tmp"
#
# 	write_format_microdvd "$tmp" "$out" >/dev/null 2>&1
# 	status=$?
# 	assertEquals "checking return value" "$RET_OK" "$status"
#
# 	data=$(head -n 1 "$out" | tail -n 1 | strip_newline | grep -c "{250}{500}line1")
# 	assertTrue "checking output 1" "[ \"$data\" -ge 1 ]"
#
# 	data=$(head -n 2 "$out" | tail -n 1 | strip_newline | grep -c "{550}{625}line2")
# 	assertTrue "checking output 2" "[ \"$data\" -ge 1 ]"
#
# 	echo "hms" > "$tmp"
# 	echo "1 00:00:10 00:00:20 line1" >> "$tmp"
# 	echo "2 00:00:22 00:00:25 line2" >> "$tmp"
#
# 	write_format_microdvd "$tmp" "$out" >/dev/null 2>&1
# 	status=$?
# 	assertEquals "checking return value" "$RET_OK" "$status"
#
# 	data=$(head -n 1 "$out" | tail -n 1 | strip_newline | grep -c "{250}{500}line1")
# 	assertTrue "checking output 3" "[ \"$data\" -ge 1 ]"
#
# 	data=$(head -n 2 "$out" | tail -n 1 | strip_newline | grep -c "{550}{625}line2")
# 	assertTrue "checking output 4" "[ \"$data\" -ge 1 ]"
#
# 	echo "hmsms" > "$tmp"
# 	echo "1 00:00:10.5 00:00:20.5 line1" >> "$tmp"
# 	echo "2 00:00:22.5 00:00:25.5 line2" >> "$tmp"
#
# 	g_outf[$___FPS]=30
# 	write_format_microdvd "$tmp" "$out" >/dev/null 2>&1
# 	status=$?
# 	assertEquals "checking return value" "$RET_OK" "$status"
#
# 	data=$(head -n 1 "$out" | tail -n 1 | strip_newline | grep -c "{315}{615}line1")
# 	assertTrue "checking output 5" "[ \"$data\" -ge 1 ]"
#
# 	data=$(head -n 2 "$out" | tail -n 1 | strip_newline | grep -c "{675}{765}line2")
# 	assertTrue "checking output 6" "[ \"$data\" -ge 1 ]"
# }
#
# test_write_format_mpl2() {
# 	local tmp=$(mktemp tmp.XXXXXXXX)
# 	local out=$(mktemp out.XXXXXXXX)
# 	local status=0
# 	local data=''
#
#
# 	echo "junk" > "$tmp"
# 	echo "junk" >> "$tmp"
#
# 	write_format_mpl2 "$tmp" "$out" >/dev/null 2>&1
# 	status=$?
# 	assertEquals "checking return value" "$RET_FAIL" "$status"
#
# 	echo "secs" > "$tmp"
# 	echo "1 10 20 line1" >> "$tmp"
# 	echo "2 22 25 line2" >> "$tmp"
#
# 	write_format_mpl2 "$tmp" "$out" >/dev/null 2>&1
# 	status=$?
# 	assertEquals "checking return value" "$RET_OK" "$status"
#
# 	data=$(head -n 1 "$out" | tail -n 1 | strip_newline | grep -c "\[100\]\[200\]line1")
# 	assertTrue "mpl2 checking output 1" "[ \"$data\" -ge 1 ]"
#
# 	data=$(head -n 2 "$out" | tail -n 1 | strip_newline | grep -c "\[220\]\[250\]line2")
# 	assertTrue "mpl2 checking output 2" "[ \"$data\" -ge 1 ]"
#
# 	echo "hms" > "$tmp"
# 	echo "1 00:00:10 00:00:20 line1" >> "$tmp"
# 	echo "2 00:00:22 00:00:25 line2" >> "$tmp"
#
# 	write_format_mpl2 "$tmp" "$out" >/dev/null 2>&1
# 	status=$?
# 	assertEquals "mpl2 checking return value" "$RET_OK" "$status"
#
# 	data=$(head -n 1 "$out" | tail -n 1 | strip_newline | grep -c "\[100\]\[200\]line1")
# 	assertTrue "mpl2 checking output 3" "[ \"$data\" -ge 1 ]"
#
# 	data=$(head -n 2 "$out" | tail -n 1 | strip_newline | grep -c "\[220\]\[250\]line2")
# 	assertTrue "mpl2 checking output 4" "[ \"$data\" -ge 1 ]"
#
# 	echo "hmsms" > "$tmp"
# 	echo "1 00:00:10.5 00:00:20.5 line1" >> "$tmp"
# 	echo "2 00:00:22.5 00:00:25.5 line2" >> "$tmp"
#
# 	write_format_mpl2 "$tmp" "$out" >/dev/null 2>&1
# 	status=$?
# 	assertEquals "mpl2 checking return value" "$RET_OK" "$status"
#
# 	data=$(head -n 1 "$out" | tail -n 1 | strip_newline | grep -c "\[105\]\[205\]line1")
# 	assertTrue "mpl2 checking output 5" "[ \"$data\" -ge 1 ]"
#
# 	data=$(head -n 2 "$out" | tail -n 1 | strip_newline | grep -c "\[225\]\[255\]line2")
# 	assertTrue "mpl2 checking output 6" "[ \"$data\" -ge 1 ]"
# }
#
# test_write_format_tmplayer() {
# 	local tmp=$(mktemp tmp.XXXXXXXX)
# 	local out=$(mktemp out.XXXXXXXX)
# 	local status=0
# 	local data=''
#
#
# 	echo "junk" > "$tmp"
# 	echo "junk" >> "$tmp"
#
# 	write_format_tmplayer "$tmp" "$out" >/dev/null 2>&1
# 	status=$?
# 	assertEquals "checking return value" "$RET_FAIL" "$status"
#
# 	echo "secs" > "$tmp"
# 	echo "1 10 20 line1" >> "$tmp"
# 	echo "2 22 25 line2" >> "$tmp"
#
# 	write_format_tmplayer "$tmp" "$out" >/dev/null 2>&1
# 	status=$?
# 	assertEquals "checking return value" "$RET_OK" "$status"
#
# 	data=$(head -n 1 "$out" | tail -n 1 | strip_newline | grep -c "00:00:10:line1")
# 	assertTrue "tmplayer checking output 1" "[ \"$data\" -ge 1 ]"
#
# 	data=$(head -n 2 "$out" | tail -n 1 | strip_newline | grep -c "00:00:22:line2")
# 	assertTrue "tmplayer checking output 2" "[ \"$data\" -ge 1 ]"
#
# 	echo "hms" > "$tmp"
# 	echo "1 00:00:10 00:00:20 line1" >> "$tmp"
# 	echo "2 00:00:22 00:00:25 line2" >> "$tmp"
#
# 	write_format_tmplayer "$tmp" "$out" >/dev/null 2>&1
# 	status=$?
# 	assertEquals "tmplayer checking return value" "$RET_OK" "$status"
#
# 	data=$(head -n 1 "$out" | tail -n 1 | strip_newline | grep -c "00:00:10:line1")
# 	assertTrue "tmplayer checking output 3" "[ \"$data\" -ge 1 ]"
#
# 	data=$(head -n 2 "$out" | tail -n 1 | strip_newline | grep -c "00:00:22:line2")
# 	assertTrue "tmplayer checking output 4" "[ \"$data\" -ge 1 ]"
#
# 	echo "hmsms" > "$tmp"
# 	echo "1 00:00:10.5 00:00:20.5 line1" >> "$tmp"
# 	echo "2 00:00:22.5 00:00:25.5 line2" >> "$tmp"
#
# 	write_format_tmplayer "$tmp" "$out" >/dev/null 2>&1
# 	status=$?
# 	assertEquals "tmplayer checking return value" "$RET_OK" "$status"
#
# 	data=$(head -n 1 "$out" | tail -n 1 | strip_newline | grep -c "00:00:10:line1")
# 	assertTrue "tmplayer checking output 5" "[ \"$data\" -ge 1 ]"
#
# 	data=$(head -n 2 "$out" | tail -n 1 | strip_newline | grep -c "00:00:22:line2")
# 	assertTrue "tmplayer checking output 6" "[ \"$data\" -ge 1 ]"
# }
#
# test_write_format_subviewer2() {
# 	local tmp=$(mktemp tmp.XXXXXXXX)
# 	local out=$(mktemp out.XXXXXXXX)
# 	local status=0
# 	local data=''
#
#
# 	echo "junk" > "$tmp"
# 	echo "junk" >> "$tmp"
#
# 	write_format_subviewer2 "$tmp" "$out" >/dev/null 2>&1
# 	status=$?
# 	assertEquals "checking return value" "$RET_FAIL" "$status"
#
# 	echo "secs" > "$tmp"
# 	echo "1 10 20 line1" >> "$tmp"
# 	echo "2 22 25 line2" >> "$tmp"
#
# 	write_format_subviewer2 "$tmp" "$out" >/dev/null 2>&1
# 	status=$?
# 	assertEquals "checking return value" "$RET_OK" "$status"
#
# 	data=$(head -n 11 "$out" | tail -n 1 | strip_newline | grep -c "00:00:10\.00,00:00:20\.00")
# 	assertTrue "subviewer2 checking output 1" "[ \"$data\" -ge 1 ]"
#
# 	data=$(head -n 14 "$out" | tail -n 1 | strip_newline | grep -c "00:00:22\.00,00:00:25\.00")
# 	assertTrue "subviewer2 checking output 2" "[ \"$data\" -ge 1 ]"
#
# 	echo "hms" > "$tmp"
# 	echo "1 00:00:10 00:00:20 line1" >> "$tmp"
# 	echo "2 00:00:22 00:00:25 line2" >> "$tmp"
#
# 	write_format_subviewer2 "$tmp" "$out" >/dev/null 2>&1
# 	status=$?
# 	assertEquals "subviewer2 checking return value" "$RET_OK" "$status"
#
# 	data=$(head -n 11 "$out" | tail -n 1 | strip_newline | grep -c "00:00:10\.00,00:00:20\.00")
# 	assertTrue "subviewer2 checking output 1" "[ \"$data\" -ge 1 ]"
#
# 	data=$(head -n 14 "$out" | tail -n 1 | strip_newline | grep -c "00:00:22\.00,00:00:25\.00")
# 	assertTrue "subviewer2 checking output 2" "[ \"$data\" -ge 1 ]"
#
# 	echo "hmsms" > "$tmp"
# 	echo "1 00:00:10.5 00:00:20.5 line1" >> "$tmp"
# 	echo "2 00:00:22.5 00:00:25.5 line2" >> "$tmp"
#
# 	write_format_subviewer2 "$tmp" "$out" >/dev/null 2>&1
# 	status=$?
# 	assertEquals "subviewer2 checking return value" "$RET_OK" "$status"
#
# 	data=$(head -n 11 "$out" | tail -n 1 | strip_newline | grep -c "00:00:10\.50,00:00:20\.50")
# 	assertTrue "subviewer2 checking output 1" "[ \"$data\" -ge 1 ]"
#
# 	data=$(head -n 14 "$out" | tail -n 1 | strip_newline | grep -c "00:00:22\.50,00:00:25\.50")
# 	assertTrue "subviewer2 checking output 2" "[ \"$data\" -ge 1 ]"
# }
#
# test_write_format_subrip() {
# 	local tmp=$(mktemp tmp.XXXXXXXX)
# 	local out=$(mktemp out.XXXXXXXX)
# 	local status=0
# 	local data=''
#
#
# 	echo "junk" > "$tmp"
# 	echo "junk" >> "$tmp"
#
# 	write_format_subrip "$tmp" "$out" >/dev/null 2>&1
# 	status=$?
# 	assertEquals "checking return value" "$RET_FAIL" "$status"
#
# 	echo "secs" > "$tmp"
# 	echo "1 10 20 line1" >> "$tmp"
# 	echo "2 22 25 line2" >> "$tmp"
#
# 	write_format_subrip "$tmp" "$out" >/dev/null 2>&1
# 	status=$?
# 	assertEquals "checking return value" "$RET_OK" "$status"
#
# 	data=$(head -n 1 "$out" | tail -n 1 | strip_newline)
# 	assertEquals "subrip checking output 1" 1 "$data"
#
# 	data=$(head -n 2 "$out" | tail -n 1 | strip_newline | grep -c "00:00:10,000 --> 00:00:20,000")
# 	assertTrue "subrip checking output 2" "[ \"$data\" -ge 1 ]"
#
# 	data=$(head -n 3 "$out" | tail -n 1 | strip_newline | grep -c "line1")
# 	assertTrue "subrip checking output 3" "[ \"$data\" -ge 1 ]"
#
# 	echo "hms" > "$tmp"
# 	echo "1 00:00:10 00:00:20 line1" >> "$tmp"
# 	echo "2 00:00:22 00:00:25 line2" >> "$tmp"
#
# 	write_format_subrip "$tmp" "$out" >/dev/null 2>&1
# 	status=$?
# 	assertEquals "subrip checking return value" "$RET_OK" "$status"
#
# 	data=$(head -n 1 "$out" | tail -n 1 | strip_newline)
# 	assertEquals "subrip checking output 4" 1 "$data"
#
# 	data=$(head -n 2 "$out" | tail -n 1 | strip_newline | grep -c "00:00:10,000 --> 00:00:20,000")
# 	assertTrue "subrip checking output 5" "[ \"$data\" -ge 1 ]"
#
# 	data=$(head -n 3 "$out" | tail -n 1 | strip_newline | grep -c "line1")
# 	assertTrue "subrip checking output 6" "[ \"$data\" -ge 1 ]"
#
# 	echo "hmsms" > "$tmp"
# 	echo "1 00:00:10.5 00:00:20.5 line1" >> "$tmp"
# 	echo "2 00:00:22.5 00:00:25.5 line2" >> "$tmp"
#
# 	write_format_subrip "$tmp" "$out" >/dev/null 2>&1
# 	status=$?
# 	assertEquals "subrip checking return value" "$RET_OK" "$status"
#
# 	data=$(head -n 1 "$out" | tail -n 1 | strip_newline)
# 	assertEquals "subrip checking output 7" 1 "$data"
#
# 	data=$(head -n 2 "$out" | tail -n 1 | strip_newline | grep -c "00:00:10,500 --> 00:00:20,500")
# 	assertTrue "subrip checking output 8" "[ \"$data\" -ge 1 ]"
#
# 	data=$(head -n 3 "$out" | tail -n 1 | strip_newline | grep -c "line1")
# 	assertTrue "subrip checking output 9" "[ \"$data\" -ge 1 ]"
# }

# shunit call
. shunit2
