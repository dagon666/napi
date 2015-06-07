#!/bin/bash

# force indendation settings
# vim: ts=4 shiftwidth=4 expandtab


########################################################################
########################################################################
########################################################################

#  Copyright (C) 2015 Tomasz Wisniewski aka 
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

########################################################################
########################################################################
########################################################################


declare -r SHUNIT_TESTS_AWK="/usr/bin/mawk"

echo "====================================="
echo "subotage unit tests with mawk"
echo "====================================="

. ./unit_subotage_common.sh

suite() {
	suite_addTest test_check_format_microdvd
	suite_addTest test_check_format_mpl2
	suite_addTest test_check_format_subrip
	suite_addTest test_check_format_subviewer2
	suite_addTest test_check_format_tmplayer
	suite_addTest test_read_format_subviewer2
	suite_addTest test_read_format_tmplayer
	suite_addTest test_read_format_microdvd
	suite_addTest test_read_format_mpl2
	suite_addTest test_read_format_subrip
	suite_addTest test_write_format_microdvd
	suite_addTest test_write_format_mpl2
	suite_addTest test_write_format_tmplayer
	suite_addTest test_write_format_subviewer2
	suite_addTest test_write_format_subrip
	suite_addTest test_guess_format
	suite_addTest test_correct_overlaps
	suite_addTest test_list_formats
	suite_addTest test_usage
	suite_addTest test_parse_argv
	suite_addTest test_verify_format
	suite_addTest test_verify_fps
	suite_addTest test_verify_argv
	suite_addTest test_detect_microdvd_fps
	suite_addTest test_correct_fps
	suite_addTest test_check_if_conv_needed
	suite_addTest test_print_format_summary
	suite_addTest test_convert_formats
	suite_addTest test_process_file
	suite_addTest test_create_output_summary
}

# shunit call
. shunit2

