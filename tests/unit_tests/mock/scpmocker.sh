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

# A set of helper functions and wrappers for scpmocker

########################################################################

declare -r \
    SCPMOCKER_FUNCTION_CMD_PREFIX="func_"
declare -r \
    SCPMOCKER_FUNCTION_ORIG_FUNC_PREFIX="___scpmocker_original_implementation."

########################################################################

scpmocker_setUp() {
    export SCPMOCKER_DB_PATH="$(mktemp -d -p "${SHUNIT_TMPDIR:-}")"
    export SCPMOCKER_BIN_PATH="$(mktemp -d -p "${SHUNIT_TMPDIR:-}")"
    export SCPMOCKER_PATH_ORIG="$PATH"
    export PATH="${SCPMOCKER_BIN_PATH}:${PATH}"
}

scpmocker_tearDown() {
    export PATH="${SCPMOCKER_PATH_ORIG}"
}

scpmocker_patchCommand() {
    ln -sf "$(which scpmocker)" "${SCPMOCKER_BIN_PATH}/${1}"
}

scpmocker_resetCommand() {
    rm -rf "${SCPMOCKER_BIN_PATH}/${1}"
}

_scpmocker_functionMock() {
    local cmd="$1"
    shift
    "${SCPMOCKER_FUNCTION_CMD_PREFIX}${cmd}" "$@"
}

scpmocker_patchFunction() {
    local funcName="$1"
    local cmd="${SCPMOCKER_FUNCTION_CMD_PREFIX}${funcName}"
    scpmocker_patchCommand "$cmd"

    # save original function's code under different name (only if it exists)
    local symbolType="$(builtin type -t "$funcName" 2>/dev/null)"
    [ -n "$symbolType" ] && [ "function" = "$symbolType" ] &&
        eval "$(echo "${SCPMOCKER_FUNCTION_ORIG_FUNC_PREFIX}${funcName}()"; \
            declare -f "$funcName" | tail -n +2)"

    # replace with a mock
    eval "${funcName}() { _scpmocker_functionMock \"${funcName}\" \"\$@\"; }"
}

scpmocker_resetFunction() {
    local funcName="$1"
    local cmd="${SCPMOCKER_FUNCTION_CMD_PREFIX}${funcName}"
    local origFuncName="${SCPMOCKER_FUNCTION_ORIG_FUNC_PREFIX}${funcName}"

    # reset the symbol
    unset -f "$funcName"

    # restore the original code
    local symbolType="$(builtin type -t "$origFuncName" 2>/dev/null)"

    [ -n "$funcName"  ] && [ -n "$symbolType" ] && {
        # restore original function's code
        eval "$(echo "${funcName}()"; \
            declare -f "$origFuncName" | tail -n +2)"
    }

    # reset the mock command
    scpmocker_resetCommand "$cmd"
}
