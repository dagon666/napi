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

# fakes/mocks
. fake/libnapi_logging_fake.sh

# module under test
. ../../libs/libnapi_argv.sh

_test_argvOptionSetter() {
    globalVariableModifiedBySetter="$1"
}

_test_argvDispatcher() {
    case "$1" in
        "--return-value")
            return "$2"
            ;;

        "--set-var")
            ___g_argvOutputHandlerType="var"
            ___g_argvOutputHandler="globalVariable"
            ___g_argvErrorMsg="no value for variable"
            ;;

        "--call-setter")
            ___g_argvOutputHandlerType="func"
            ___g_argvOutputHandler="_test_argvOptionSetter"
            ___g_argvErrorMsg="no value for option setter"
            ;;
    esac
}

test_that_argvParser_GV_forwardsArgvReturnValue() {
    local rv=123
    argv_argvParser_GV _test_argvDispatcher "--return-value" "$rv"
    assertEquals "checking forwarded dispatcher's return value" "$rv" $?
}

test_that_argvParser_GV_setsTheGlobalVariable() {
    local newValue="new_value_for_global with white characters"
    globalVariable="empty"

    assertNotEquals "checking global variable initial value" \
        "$globalVariable" "$newValue"

    argv_argvParser_GV _test_argvDispatcher "--set-var" "$newValue"

    assertEquals "checking globalVariable value" \
        "$globalVariable" "$newValue"
}

test_that_argvParser_GV_callsTheSetter() {
    local newValue="new value for setter"
    argv_argvParser_GV _test_argvDispatcher "--call-setter" "$newValue"
    assertEquals "checking globalVariable value set by setter" \
        "$newValue" "$globalVariableModifiedBySetter"
}

test_that_argvParser_GV_failsIfNoValueForOption() {
    argv_argvParser_GV _test_argvDispatcher "--call-setter" "$newValue"

    assertEquals "checking for return value" \
        $G_RETFAIL "$?"
}

# shunit call
. shunit2
