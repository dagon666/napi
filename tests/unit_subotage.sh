#!/bin/bash

################################################################################

#  Copyright (C) 2014 Tomasz Wisniewski aka 
#       DAGON <tomasz.wisni3wski@gmail.com>
#
#  http://github.com/dagon666
#  http://pcarduino.blogspot.co.ul
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

################################################################################

#
# source common unit lib
#
. lib/unit_common.sh

#
# source the code of the original script
#
. "$g_install_path/subotage.sh" 2>&1 > /dev/null

################################################################################

#
# tests env setup
#
oneTimeSetUp() {
	_prepare_env
    cp -rv "$g_assets_path/napi_test_files/subtitles" "$g_assets_path/$g_ut_root/"
}


#
# tests env tear down
#
oneTimeTearDown() {
	_purge_env
}

################################################################################

test_check_format_microdvd() {
	local tmp=$(mktemp test.XXXXXXXX)
	local match=''
	_save_subotage_globs

	echo "junk" > "$tmp"
	echo "{123}{456}first line" >> "$tmp"
	echo "{123}{456}second line" >> "$tmp"

	match=$(check_format_microdvd "$tmp")
	assertEquals "checking the first line" "microdvd 2" "$match"

	echo "junk" > "$tmp"
	echo "junk" >> "$tmp"
	echo "junk" >> "$tmp"
	echo "junk" >> "$tmp"
	match=$(check_format_microdvd "$tmp")
	assertEquals "checking the first line" "not_detected" "$match"

	match=$(check_format_microdvd "$g_assets_path/$g_ut_root/subtitles/1_microdvd.txt")
	assertEquals "checking the first line and fps from real file" "microdvd 1 23.976" "$match"

	match=$(check_format_microdvd "$g_assets_path/$g_ut_root/subtitles/2_microdvd.txt")
	assertEquals "checking the first line" "microdvd 1" "$match"

	match=$(check_format_microdvd "$g_assets_path/$g_ut_root/subtitles/3_microdvd.txt")
	assertEquals "checking the first line" "microdvd 1 23.976" "$match"

	# try with other formats to make sure it doesn't catch any
	match=$(check_format_microdvd "$g_assets_path/$g_ut_root/subtitles/2_newline_subrip.txt")
	assertEquals "checking subrip no detection" "not_detected" "$match"
	match=$(check_format_microdvd "$g_assets_path/$g_ut_root/subtitles/1_tmplayer.txt")
	assertEquals "checking tmplayer no detection" "not_detected" "$match"
	match=$(check_format_microdvd "$g_assets_path/$g_ut_root/subtitles/1_subviewer2.sub")
	assertEquals "checking subviewer2 no detection" "not_detected" "$match"
	match=$(check_format_microdvd "$g_assets_path/$g_ut_root/subtitles/1_mpl2.txt")
	assertEquals "checking mpl2 no detection" "not_detected" "$match"

	unlink "$tmp"
	_restore_subotage_globs
	return 0
}


test_check_format_mpl2() {
	local tmp=$(mktemp test.XXXXXXXX)
	local match=''
	_save_subotage_globs

	echo "junk" > "$tmp"
	echo "[123][456]first line" >> "$tmp"
	echo "[123][456]second line" >> "$tmp"

	match=$(check_format_mpl2 "$tmp")
	assertEquals "checking the first line" "mpl2 2" "$match"

	echo "junk" > "$tmp"
	echo "junk" >> "$tmp"
	echo "junk" >> "$tmp"
	echo "junk" >> "$tmp"
	match=$(check_format_mpl2 "$tmp")
	assertEquals "checking the first line" "not_detected" "$match"

	match=$(check_format_mpl2 "$g_assets_path/$g_ut_root/subtitles/1_mpl2.txt")
	assertEquals "checking the first line and fps from real file" "mpl2 1" "$match"

	match=$(check_format_mpl2 "$g_assets_path/$g_ut_root/subtitles/2_mpl2.txt")
	assertEquals "checking the first line 2_mpl2.txt" "mpl2 1" "$match"

	# try with other formats to make sure it doesn't catch any
	match=$(check_format_mpl2 "$g_assets_path/$g_ut_root/subtitles/2_newline_subrip.txt")
	assertEquals "checking subrip no detection" "not_detected" "$match"
	match=$(check_format_mpl2 "$g_assets_path/$g_ut_root/subtitles/1_tmplayer.txt")
	assertEquals "checking tmplayer no detection" "not_detected" "$match"
	match=$(check_format_mpl2 "$g_assets_path/$g_ut_root/subtitles/1_subviewer2.sub")
	assertEquals "checking subviewer2 no detection" "not_detected" "$match"
	match=$(check_format_mpl2 "$g_assets_path/$g_ut_root/subtitles/1_microdvd.txt")
	assertEquals "checking microdvd no detection" "not_detected" "$match"

	unlink "$tmp"
	_restore_subotage_globs
	return 0

}


test_check_format_subrip() {
	local tmp=$(mktemp test.XXXXXXXX)
	local match=''
	_save_subotage_globs

	echo "junk" > "$tmp"
	echo "junk" >> "$tmp"
	echo "1 00:00:02,123 --> 00:00:12,234" >> "$tmp"
	echo "some subs line" >> "$tmp"

	match=$(check_format_subrip "$tmp")
	assertEquals "checking the first line" "subrip 3 inline" "$match"

	echo "junk" > "$tmp"
	echo "junk" >> "$tmp"
	echo "junk" >> "$tmp"
	echo "junk" >> "$tmp"
	match=$(check_format_subrip "$tmp")
	assertEquals "check not detecting junk" "not_detected" "$match"

	match=$(check_format_subrip "$g_assets_path/$g_ut_root/subtitles/1_inline_subrip.txt")
	assertEquals "checking the first line from real file" "subrip 1 inline" "$match"

	match=$(check_format_subrip "$g_assets_path/$g_ut_root/subtitles/2_newline_subrip.txt")
	assertEquals "checking the first line (newline)" "subrip 1 newline" "$match"

	match=$(check_format_subrip "$g_assets_path/$g_ut_root/subtitles/3_subrip.txt")
	assertEquals "checking the first line (newline)" "subrip 5 newline" "$match"

	# try with other formats to make sure it doesn't catch any
	match=$(check_format_subrip "$g_assets_path/$g_ut_root/subtitles/1_microdvd.txt")
	assertEquals "checking microdvd no detection" "not_detected" "$match"
	match=$(check_format_subrip "$g_assets_path/$g_ut_root/subtitles/1_tmplayer.txt")
	assertEquals "checking tmplayer no detection" "not_detected" "$match"
	match=$(check_format_subrip "$g_assets_path/$g_ut_root/subtitles/1_subviewer2.sub")
	assertEquals "checking subviewer2 no detection" "not_detected" "$match"
	match=$(check_format_subrip "$g_assets_path/$g_ut_root/subtitles/1_mpl2.txt")
	assertEquals "checking mpl2 no detection" "not_detected" "$match"

	unlink "$tmp"
	_restore_subotage_globs
	return 0
}


test_check_format_subviewer2() {
	local tmp=$(mktemp test.XXXXXXXX)
	local match=''
	_save_subotage_globs

	echo "junk" > "$tmp"
	echo "junk" >> "$tmp"
	echo "00:00:02.123,00:00:12.234" >> "$tmp"
	echo "some subs line" >> "$tmp"

	match=$(check_format_subviewer2 "$tmp")
	assertEquals "checking the first line" "subviewer2 3 0" "$match"

	echo "junk" > "$tmp"
	echo "junk" >> "$tmp"
	echo "junk" >> "$tmp"
	echo "junk" >> "$tmp"
	match=$(check_format_subviewer2 "$tmp")
	assertEquals "check not detecting junk" "not_detected" "$match"

	match=$(check_format_subviewer2 "$g_assets_path/$g_ut_root/subtitles/1_subviewer2.sub")
	assertEquals "checking the first line from real file" "subviewer2 11 1" "$match"

	# try with other formats to make sure it doesn't catch any
	match=$(check_format_subviewer2 "$g_assets_path/$g_ut_root/subtitles/1_microdvd.txt")
	assertEquals "checking microdvd no detection" "not_detected" "$match"
	match=$(check_format_subviewer2 "$g_assets_path/$g_ut_root/subtitles/1_tmplayer.txt")
	assertEquals "checking tmplayer no detection" "not_detected" "$match"
	match=$(check_format_subviewer2 "$g_assets_path/$g_ut_root/subtitles/1_inline_subrip.txt")
	assertEquals "checking subrip no detection" "not_detected" "$match"
	match=$(check_format_subviewer2 "$g_assets_path/$g_ut_root/subtitles/2_newline_subrip.txt")
	assertEquals "checking subrip newline no detection" "not_detected" "$match"
	match=$(check_format_subviewer2 "$g_assets_path/$g_ut_root/subtitles/1_mpl2.txt")
	assertEquals "checking mpl2 no detection" "not_detected" "$match"

	unlink "$tmp"
	_restore_subotage_globs
	return 0

}

test_check_format_tmplayer() {
	local tmp=$(mktemp test.XXXXXXXX)
	local match=''
	_save_subotage_globs

	echo "junk" > "$tmp"
	echo "junk" >> "$tmp"
	echo "00:00:02=line of subs" >> "$tmp"
	echo "00:02:02=line of subs" >> "$tmp"

	match=$(check_format_tmplayer "$tmp")
	assertEquals "checking the first line" "tmplayer 3 2 0 =" "$match"

	echo "junk" > "$tmp"
	echo "junk" >> "$tmp"
	echo "0:00:02:line of subs" >> "$tmp"
	echo "0:02:02:line of subs" >> "$tmp"

	match=$(check_format_tmplayer "$tmp")
	assertEquals "checking the first line" "tmplayer 3 1 0 :" "$match"

	echo "junk" > "$tmp"
	echo "junk" >> "$tmp"
	echo "junk" >> "$tmp"
	echo "junk" >> "$tmp"
	match=$(check_format_tmplayer "$tmp")
	assertEquals "check not detecting junk" "not_detected" "$match"

	match=$(check_format_tmplayer "$g_assets_path/$g_ut_root/subtitles/1_tmplayer.txt")
	assertEquals "checking the first line from real file" "tmplayer 1 2 0 :" "$match"

	match=$(check_format_tmplayer "$g_assets_path/$g_ut_root/subtitles/2_tmplayer.txt")
	assertEquals "checking the first line from real file" "tmplayer 1 1 0 :" "$match"

	match=$(check_format_tmplayer "$g_assets_path/$g_ut_root/subtitles/3_tmplayer.txt")
	assertEquals "checking the first line from real file" "tmplayer 1 2 1 :" "$match"

	match=$(check_format_tmplayer "$g_assets_path/$g_ut_root/subtitles/4_tmplayer.txt")
	assertEquals "checking the first line from real file" "tmplayer 1 2 1 =" "$match"

	# # try with other formats to make sure it doesn't catch any
	match=$(check_format_tmplayer "$g_assets_path/$g_ut_root/subtitles/1_microdvd.txt")
	assertEquals "checking microdvd no detection" "not_detected" "$match"
	match=$(check_format_tmplayer "$g_assets_path/$g_ut_root/subtitles/1_inline_subrip.txt")
	assertEquals "checking subrip no detection" "not_detected" "$match"
	match=$(check_format_tmplayer "$g_assets_path/$g_ut_root/subtitles/1_mpl2.txt")
	assertEquals "checking mpl2 no detection" "not_detected" "$match"

	# not checking subviewer2 and newline subrip
	# because I know that this detector conflict with those
	# that's why it is being placed as last

	unlink "$tmp"
	_restore_subotage_globs
	return 0
}


test_read_format_subviewer2() {
	return 0
}

test_read_format_tmplayer() {
	return 0
}

test_read_format_microdvd() {
	return 0
}

test_read_format_mpl2() {
	return 0
}

test_read_format_subrip() {
	return 0
}

test_write_format_subviewer2() {
	return 0
}

test_write_format_tmplayer() {
	return 0
}

test_write_format_microdvd() {
	return 0
}

test_write_format_mpl2() {
	return 0
}

test_write_format_subrip() {
	return 0
}

test_guess_format() {
	
	return 0
}

test_correct_overlaps() {

	return 0
}

test_list_formats() {
	
	return 0
}

test_usage() {

	return 0
}

test_parse_argv() {
	
	return 0
}

test_verify_format() {

	return 0
}

test_verify_fps() {
	
	return 0
}

test_verify_argv() {

	return 0
}

test_detect_microdvd_fps() {
	
	return 0
}

test_correct_fps() {
	_save_subotage_globs

	g_inf[$___FPS]=25
	g_outf[$___FPS]=0
	correct_fps
	assertEquals "checking if fps has been synced" "${g_inf[$___FPS]}" "${g_outf[$___FPS]}"


	g_inf[$___FPS]=25
	g_outf[$___FPS]=23
	correct_fps
	assertEquals "checking if fps has not been synced" 23 "${g_outf[$___FPS]}"

	_restore_subotage_globs
	return 0
}

test_check_if_conv_needed() {
	local status=0

	_save_subotage_globs

	g_inf[$___FORMAT]="subrip"
	g_outf[$___FORMAT]="SUBRIP"
	check_if_conv_needed
	status=$?
	assertEquals "conversion not needed rv check" $RET_NOACT "$status"

	g_inf[$___FORMAT]="subrip"
	g_outf[$___FORMAT]="mpl2"
	check_if_conv_needed
	status=$?
	assertEquals "conversion needed rv check" $RET_OK "$status"

	g_inf[$___FORMAT]="microdvd"
	g_outf[$___FORMAT]="microdvd"

	g_inf[$___FPS]="23.456"
	g_outf[$___FPS]="23.456"
	check_if_conv_needed 2>&1 > /dev/null
	status=$?
	assertEquals "conversion not needed udvd same fps" $RET_NOACT "$status"
	
	g_inf[$___FPS]="23.456"
	g_outf[$___FPS]="29.756"
	check_if_conv_needed
	status=$?
	assertEquals "conversion needed udvd != fps" $RET_OK "$status"

	_restore_subotage_globs
	return 0
}


test_print_format_summary() {
	local presence=0
	_save_subotage_globs

	presence=$(print_format_summary "PREFIX_" "some_file" | grep -c "PREFIX_")
	assertEquals "checking summary prefix" 0 "$presence"

	g_output[$___VERBOSIRTY]=2
	presence=$(print_format_summary "PREFIX_" "some_file" | grep -c "PREFIX_")
	assertTrue "checking summary prefix" "[ $presence -gt 0 ]"

	g_output[$___VERBOSIRTY]=1
	g_getinfo=1
	presence=$(print_format_summary "PREFIX_" "some_file" | grep -c "PREFIX_")
	assertTrue "checking summary prefix" "[ $presence -gt 0 ]"

	_restore_subotage_globs
	return 0
}


test_convert_formats() {
	
	return 0
}


test_process_file() {
	# empty this will be verified with system tests
	return 0
}


test_create_output_summary() {
	local tmp=$(mktemp ipc.XXXXXXXX)
	local data=''
	_save_subotage_globs

	g_ipc_file="$tmp"
	g_output[$___CNT]=666
	create_output_summary
	read data < "$tmp"

	assertEquals "comparing cnt values" 666 "$data"

	unlink "$tmp"
	_restore_subotage_globs
	return 0
}

# shunit call
. shunit2
