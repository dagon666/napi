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
. mock/scpmocker.sh

# module under test
. ../../libs/libnapi_fs.sh

setUp() {
    scpmocker_setUp
}

tearDown() {
    scpmocker_tearDown
}

_genericForwardTest() {
    local cmd="$1"
    local cmdIndex="$2"
    local func="$3"
    local cmdOutput="${4:-12345}"

    # set-up mock
    scpmocker -c "$cmd" program -s "$cmdOutput"
    scpmocker_patchCommand "$cmd"

    # set-up fs
    # shellcheck disable=SC2034
    ___g_fsWrappers[$cmdIndex]="$cmd"

    local args=("some" "positional" "arguments")

    assertEquals "check call output for $func" \
        "$cmdOutput" "$("$func" "${args[@]}")"

    assertEquals "check mock call count" \
        1 "$(scpmocker -c "$cmd" status -C)"

    assertEquals "check mock argumens" \
        "${args[*]}" "$(scpmocker -c "$cmd" status -A 1)"
}

test_fs_stat_forwardsCall() {
    _genericForwardTest "stat" "$___g_fsStat" "fs_stat_SO" "12345"
}

test_fs_base64Decode_forwardsCall() {
    _genericForwardTest "base64" "$___g_fsBase64" "fs_base64Decode_SO" "12345"
}

test_fs_md5_forwardsCall() {
    _genericForwardTest "md5" "$___g_fsMd5" "fs_md5_SO" "12345"
}

test_fs_cp_forwardsCall() {
    _genericForwardTest "cp" "$___g_fsCp" "fs_cp" "12345"
}

test_fs_setCp_setsTheWrapper() {
    local wrapper="some wrapper"
    fs_setCp_GV "$wrapper"

    assertEquals "check for wrapper value" \
        "$wrapper" "${___g_fsWrappers[$___g_fsCp]}"
}

test_fs_unlink_forwardsCall() {
    _genericForwardTest "unlink" "$___g_fsUnlink" "fs_unlink" "12345"
}

test_fs_7z_forwardsCallIf7zDetected() {
    _genericForwardTest "7z" "$___g_fs7z" "fs_7z_SO" "12345"
}

test_fs_7z_doesntForwardCallIf7zIsNotDetected() {

    # set-up mock
    scpmocker -c "7z" program
    scpmocker -c "7za" program

    scpmocker_patchCommand "7z"
    scpmocker_patchCommand "7za"

    # set-up fs
    # shellcheck disable=SC2034
    ___g_fsWrappers[$___g_fs7z]='none'

    assertNull "check call output for $func" \
        "$(fs_7z_SO "some" "positional" "args")"

    assertEquals "check mock call count" \
        0 "$(scpmocker -c "7z" status -C)"

    assertEquals "check mock call count" \
        0 "$(scpmocker -c "7za" status -C)"
}

test_fs_is7zAvailableReturnsCorrectValues() {
    ___g_fsWrappers[$___g_fs7z]='none'

    assertFalse "check for return value when not available" \
        fs_is7zAvailable

    ___g_fsWrappers[$___g_fs7z]='7z'

    assertTrue "check for return value when available" \
        fs_is7zAvailable
}

test_fs_garbageCollect_CollectsTheFileIfItExists() {
    local tmpFile="$(mktemp -p "$SHUNIT_TMPDIR")"
    local garbageLog="$(mktemp -p "$SHUNIT_TMPDIR")"

    assertTrue "check if exists initially" \
        "[ -e $tmpFile ]"


    ___g_fsGarbageCollectorLog="$garbageLog"
    fs_garbageCollect "$tmpFile"

    assertEquals "check log contents" \
        "$tmpFile" "$(<"$garbageLog")"
}

test_fs_garbageCollect_doesntCollectTheFileIfItDoesntExists() {
    local tmpFile="$(mktemp -p "$SHUNIT_TMPDIR")"
    local garbageLog="$(mktemp -p "$SHUNIT_TMPDIR")"

    rm -rf "$tmpFile"

    assertFalse "check if exists initially" \
        "[ -e $tmpFile ]"

    ___g_fsGarbageCollectorLog="$garbageLog"
    fs_garbageCollect "$tmpFile"

    assertNull "check log contents" \
        "$(<"$garbageLog")"
}

# shunit call
. shunit2
