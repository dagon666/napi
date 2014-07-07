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

test_check_format_microdvd() {

	return 0
}

test_check_format_mpl2() {
	return 0
}

test_check_format_subrip() {
	return 0
}

test_check_format_subviewer2() {
	return 0
}

test_check_format_tmplayer() {
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

	return 0
}

test_convert_formats() {
	
	return 0
}

test_process_file() {

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
