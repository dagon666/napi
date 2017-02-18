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
. ../../libs/libnapi_retvals.sh
. ../../libs/libnapi_wrappers.sh


# fakes/mocks
. mock/scpmocker.sh

# module under test
. ../../libs/libnapi_logging.sh

setUp() {
    scpmocker_setUp

    # restore original values
    ___g_output=( 1 'none' 0 1 0 )
}

tearDown() {
    scpmocker_tearDown
}

#
# general function to test printing routines
#
_test_printers() {
    local printer="$1"
    local verbosity="$2"
    local str='empty line variable'
    local output=
    local lines=0

    output=$("logging_${printer}" '' "$str")
    assertTrue "$printer return value - always success" $?

    lines=$(echo "$output" | grep -c "0: $str")
    assertEquals "$printer with default verbosity" \
        0 "$lines"

    ___g_output[$___g_output_verbosity]="$verbosity"
    output=$("logging_${printer}" '' "$str")
    lines=$(echo "$output" | grep -c "0: $str")
    assertEquals "$printer with verbosity = $verbosity" \
        1 "$lines"

    output=$("logging_${printer}" 123 "$str")
    lines=$(echo "$output" | grep -c "123: $str")
    assertEquals "$printer with verbosity = $verbosity + line number" \
        1 "$lines"

    ___g_output[$___g_output_verbosity]=1
}

test_logging_debug() {
    _test_printers 'debug' 3
}

test_logging_info() {
    _test_printers 'info' 2
}

test_logging_warning() {
    local output=
    output=$(logging_warning "warning message" | grep -c "WARNING")
    assertEquals "warning message format" \
        1 "$output"

    ___g_output[$___g_output_verbosity]=0
    output=$(logging_warning "warning message" | grep -c "WARNING")
    assertEquals "warning message format" \
        0 "$output"
}

test_logging_error() {
    local output=
    output=$(logging_error "error message" 2>&1 | grep -c "ERROR")
    assertEquals "error message format 1" \
        1 "$output"

    ___g_output[$___g_output_verbosity]=0
    output=$(logging_error "error message" 2>&1 | grep -c "ERROR")
    assertEquals "error message format 2" \
        1 "$output"
}

test_logging_msg() {
    local output=
    output=$(logging_msg "message" | grep -c " - message")
    assertEquals "message format" \
        1 "$output"

    ___g_output[$___g_output_verbosity]=0
    output=$(logging_msg "message" | grep -c " - message")
    assertEquals "message format" \
        0 "$output"
}

test_logging_status() {
    local output=
    output=$(logging_status 'INFO' "message" | grep -c "INFO")
    assertEquals "status format" \
        1 "$output"

    ___g_output[$___g_output_verbosity]=0
    output=$(logging_status 'INFO' "message" | grep -c "INFO")
    assertEquals "message format" \
        0 $output
}

test_logging_blit_producesExpectedOutput() {
	___g_output[$___g_output_forkid]=0
	___g_output[$___g_output_msgcnt]=8
	local output=

	output=$(_logging_blit "some message")
	assertEquals "testing blit function and output format" \
        "00:0008 some message" "$output"

	_logging_blit "abc" > /dev/null

	assertEquals "checking the fork id status" \
        0 "${___g_output[$___g_output_forkid]}"

	assertEquals "checking the msg cnt" \
        9  "${___g_output[$___g_output_msgcnt]}"
}

test_logging_setVerbosity_configuresGlobalValue() {
    local expected=0

    for i in {1..16}; do
        expected="$i"
        [ "$i" -gt 4 ] && expected=1

        logging_setVerbosity "$i" >/dev/null

        assertEquals "check level for $i requested" \
            "$expected" "${___g_output[$___g_output_verbosity]}"
    done
}

test_logging_setMessageCounter_configuresGlobalValue() {
    for i in {1..16}; do
        logging_setMsgCounter "$i"
        assertEquals "check level for $i requested" \
            "$i" "${___g_output[$___g_output_msgcnt]}"
    done
}

test_logging_setForkId_configuresGlobalValue() {
    for i in {1..16}; do
        logging_setForkId "$i"
        assertEquals "check level for $i requested" \
            "$i" "${___g_output[$___g_output_forkid]}"
    done
}

test_logging_getVerbosity_returnsGlobalVariableValues() {
    for i in {1..16}; do
        ___g_output[$___g_output_verbosity]="$i"

        assertEquals "check value for $i" \
            "$i" "$(logging_getVerbosity_SO)"
    done
}

test_logging_getMsgCounter_returnsGlobalVariableValues() {
    for i in {1..16}; do
        ___g_output[$___g_output_msgcnt]="$i"

        assertEquals "check value for $i" \
            "$i" "$(logging_getMsgCounter_SO)"
    done
}

test_logging_getForkId_returnsGlobalVariableValues() {
    for i in {1..16}; do
        ___g_output[$___g_output_forkid]="$i"

        assertEquals "check value for $i" \
            "$i" "$(logging_getForkId_SO)"
    done
}

test_logging_raiseLogOverwrite_setsGlobalFlag() {
    ___g_output[$___g_output_owrt]=0
    logging_raiseLogOverwrite
    assertEquals "check flag raised" \
        1 "${___g_output[$___g_output_owrt]}"

    logging_raiseLogOverwrite
    assertEquals "check flag raised (2nd attempt)" \
        1 "${___g_output[$___g_output_owrt]}"
}

test_logging_clearLogOverwrite_clearsGlobalFlag() {
    ___g_output[$___g_output_owrt]=1
    logging_clearLogOverwrite
    assertEquals "check flag cleared" \
        0 "${___g_output[$___g_output_owrt]}"

    logging_clearLogOverwrite
    assertEquals "check flag cleared (2nd attempt)" \
        0 "${___g_output[$___g_output_owrt]}"
}

test_logging_setLogFile_redirectsOutputToLogFile() {
    local logFile=$(mktemp -p "$SHUNIT_TMPDIR")
    local msg="message to be logged"

    ___g_output[$___g_output_owrt]=1
    logging_setLogFile "$logFile"

    logging_error "$msg"
    _logging_redirectToStdout

    assertEquals "check file contents" \
        "00:0002 ERROR -> $msg" "$(<${logFile})"


}

# shunit call
. shunit2

