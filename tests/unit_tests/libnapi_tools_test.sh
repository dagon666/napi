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
. ../../libs/libnapi_retvals.sh
. ../../libs/libnapi_wrappers.sh

# fakes/mocks
. fake/libnapi_logging_fake.sh
. mock/scpmocker.sh

# module under test
. ../../libs/libnapi_tools.sh

declare -a originalToolsArray=()

oneTimeSetUp() {
    originalToolsArray=( "${___g_tools[@]}" )
}

#
# tests env setup
#
setUp() {
    # restore original values
    ___g_tools=( "${originalToolsArray[@]}" )
    scpmocker_setUp
}

#
# tests env tear down
#
tearDown() {
    scpmocker_tearDown
}

test_tools_verifyFunctionPresence_worksCorrectly() {
    local fakeFuncs=( "non-existing function" "cp" "mv" \
       "made up function" )
    local func=

    for func in $(compgen -A function); do
        tools_verifyFunctionPresence "$func"
        assertTrue "checking existince of [$func]" \
            "$?"
    done

    for func in "${fakeFuncs[@]}"; do
        tools_verifyFunctionPresence "$func"
        assertFalse "checking existince of [$func]" \
            "$?"
    done
}

test_tools_verifyToolPresence_returnsTrueForFunctions() {
    local func=
    for func in $(compgen -A function); do
        tools_verifyToolPresence "$func"
        assertTrue "succeeds for [$func]" \
            "$?"
    done
}

test_tools_verifyToolPresence_succeedsForCoreTools() {
    local tools=( 'mv' 'cp' 'bash' 'ls' )
    local t=
    for t in "${tools[@]}"; do
        tools_verifyToolPresence "$t"
        assertTrue "succeeds for [$t]" \
            "$?"
    done
}

test_tools_verifyToolPresence_succeedsForBuiltIns() {
    local tools=( 'case' 'function' 'esac' 'if' 'fi' )
    local t=
    for t in "${tools[@]}"; do
        tools_verifyToolPresence "$t"
        assertTrue "succeeds for [$t]" \
            "$?"
    done
}

test_tools_verifyToolPresence_failsForNonExistingTools() {
    local tools=( 'fake-tool' 'other-fake-tool' 'abcdef' 'xxx' )
    local t=
    for t in "${tools[@]}"; do
        tools_verifyToolPresence "$t"
        assertFalse "fails for [$t]" \
            "$?"
    done
}

test_tools_addTool_GV_addsNewTools() {
    ___g_tools=()

    tools_addTool_GV "myTool"

    assertEquals "checking tools after myTool addition" \
        "myTool=1" "${___g_tools[*]}"

    tools_addTool_GV "myTool2" "0"

    assertEquals "checking tools after myTool2 addition" \
        "myTool=1 myTool2=0" "${___g_tools[*]}"
}

test_tools_isDetected_returnsTrueForDetectedTools() {
    ___g_tools=( "detectedTool=1" "undetectedTool=0" \
        "group:otherDetected=1" "group:otherUndetected=0" )

    tools_isDetected "detectedTool"
    assertTrue "checking detectedTool" "$?"

    tools_isDetected "undetectedTool"
    assertFalse "checking undetectedTool" "$?"

    tools_isDetected "otherDetected"
    assertTrue "checking otherDetected" "$?"

    tools_isDetected "otherUndetected"
    assertFalse "checking otherUndetected" "$?"
}

test_tools_getFirstAvailableFromGroup_succeedsIfOneToolAvailable() {
    ___g_tools=( group1:unav1=0 group2:unav2=0 \
        group1:av1=1 detected=1 \
        group1:av2=1)
    local tool=

    tool="$(tools_getFirstAvailableFromGroup_SO "group1")"

    assertTrue "check return value for group1" \
        "$?"

    assertEquals "check tool for group1" \
        "av1" "$tool"

    tool="$(tools_getFirstAvailableFromGroup_SO "group2")"

    assertFalse "check return value for group2" \
        "$?"

    assertEquals "check tool for group2" \
        "" "$tool"
}

test_tools_isInGroup_worksCorrectly() {
    ___g_tools=( g1:t1=0 g1:t2=1 g1:t3=0 \
        g2:t1=0 g2:t2=0 g2:t3=0 )

    local g=
    local t=

    for g in {1..2}; do
        for t in {1..3}; do
            tools_isInGroup "g${g}" "t${t}"
            assertTrue "check existing tool t${t}" "$?"
        done
    done

    for g in {1..2}; do
        for t in {4..9}; do
            tools_isInGroup "g${g}" "t${t}"
            assertFalse "check non-existing tool t${t}" "$?"
        done
    done
}

test_tools_isInGroupAndDetected_failsForNonExistingGroup() {
    ___g_tools=( g1:t1=0 g1:t2=1 g1:t3=0 \
        g2:t1=0 g2:t2=0 g2:t3=0 )

    tools_isInGroupAndDetected "non-existing-group" "t1"
    assertFalse "check for failure due to non-existing group" "$?"
}

test_tools_isInGroupAndDetected_failsForNonExistingToolInGroup() {
    ___g_tools=( g1:t1=0 g1:t2=1 g1:t3=0 \
        g2:t1=0 g2:t2=0 g2:t3=0 )

    tools_isInGroupAndDetected "g1" "non-existing-tool"
    assertFalse "check for failure due to non-existing tool" "$?"
}

test_tools_isInGroupAndDetected_worksCorrectly() {
    ___g_tools=( g1:t1=0 g1:t2=1 g1:t3=0 \
        g2:t1=0 g2:t2=0 g2:t3=0 )

    tools_isInGroupAndDetected "g1" "t1"
    assertFalse "check for failure due to non-detected tool g1:t1" "$?"

    tools_isInGroupAndDetected "g1" "t2"
    assertTrue "check for success for tool g1:t2" "$?"

    tools_isInGroupAndDetected "g1" "t3"
    assertFalse "check for failure due to non-detected tool g1:t3" "$?"

    tools_isInGroupAndDetected "g2" "t1"
    assertFalse "check for failure due to non-detected tool g2:t1" "$?"

    tools_isInGroupAndDetected "g2" "t1"
    assertFalse "check for failure due to non-detected tool g2:t2" "$?"

    tools_isInGroupAndDetected "g2" "t3"
    assertFalse "check for failure due to non-detected tool g3:t3" "$?"
}

test_tools_countGroupMembers_returnsZeroForNonExistingGroup() {
    ___g_tools=( g1:t1=0 g1:t2=1 g1:t3=0 \
        g2:t1=0 g2:t2=0 g2:t3=0 )
    local cnt=0

    cnt=$(tools_countGroupMembers_SO "non-existing-group")

    assertEquals "check count of zero" \
        "0" "$cnt"
}

test_tools_countGroupMembers_returnsCorrectMemberCount() {
    ___g_tools=( g1:t1=0 g1:t2=1 g1:t3=0 \
        g2:t1=0 g2:t2=0 g2:t3=0 g2:t4=1 \
        g3:abc=0 )
    local expected=( 3 4 1 )
    local cnt=0
    local g=0

    for g in {1..3}; do
        cnt=$(tools_countGroupMembers_SO "g${g}")

        assertTrue "check return value for g${g}" "$?"

        assertEquals "check count for g${g}" \
            "${expected[$(( g - 1 ))]}" "$cnt"
    done
}

test_tools_countDetectedGroupMembers_returnsZeroForNonExistingGroup() {
    ___g_tools=( g1:t1=0 g1:t2=1 g1:t3=0 \
        g2:t1=0 g2:t2=0 g2:t3=0 g2:t4=1 \
        g3:abc=0 )
    local cnt=0

    cnt=$(tools_countDetectedGroupMembers_SO "non-existing-group")
    assertEquals "check count for g${g}" \
        "0" "$cnt"
}

test_tools_countDetectedGroupMembers_returnsCorrectMembersCount() {
    ___g_tools=( g1:t1=0 g1:t2=1 g1:t3=0 \
        g2:t1=0 g2:t2=2 g2:t3=0 g2:t4=1 \
        g3:abc=0 g3:def=0 )

    local expected=( 1 2 0 )
    local cnt=0
    local g=0

    for g in {1..3}; do
        cnt=$(tools_countDetectedGroupMembers_SO "g${g}")

        assertTrue "check return value for g${g}" "$?"

        assertEquals "check count for g${g}" \
            "${expected[$(( g - 1 ))]}" "$cnt"
    done
}

test_tools_toString_returnsCorrectOutputValue() {
    ___g_tools=( abc=1 def=0 g1:xxx=0 g1:xyz=1 )

    assertEquals "check output value" \
        "${___g_tools[*]}" "$(tools_toString_SO)"
}

test_tools_toList_returnsCorrectOutputValue() {
    ___g_tools=( abc=1 def=0 g1:xxx=0 g1:xyz=1 )
    local str=
    local resul=

    str=$( local IFS=$'\n'; echo "${___g_tools[*]}" )

    result="$(tools_toList_SO | wc -l)"
    assertEquals "check number of lines" \
        "4" "$result"

    str="$(echo "$str" | tr '\n' ',')"
    result="$(tools_toList_SO | tr '\n' ',')"
    assertEquals "check output" \
        "$str" "$result"
}

test_tools_groupToString_returnsCorrectOutputValue() {
    ___g_tools=( g1:t1=0 g1:t2=1 g1:t3=0 \
        g2:t1=0 g2:t2=2 g2:t3=0 g2:t4=1 \
        g3:abc=0 g3:def=0 )

    assertEquals "check output for g1" \
        "t1=0 t2=1 t3=0" "$(tools_groupToString_SO g1)"

    assertEquals "check output for g2" \
        "t1=0 t2=2 t3=0 t4=1" "$(tools_groupToString_SO g2)"

    assertEquals "check output for g3" \
        "abc=0 def=0" "$(tools_groupToString_SO g3)"
}

test_tools_groupToList_returnsCorrectOutputValue() {
    ___g_tools=( g1:t1=0 g1:t2=1 g1:t3=0 \
        g2:t1=0 g2:t2=2 g2:t3=0 g2:t4=1 \
        g3:abc=0 g3:def=0 )

    assertEquals "check output for g1" \
        "3" "$(tools_groupToList_SO g1 | wc -l)"

    assertEquals "check output for g2" \
        "4" "$(tools_groupToList_SO g2 | wc -l)"

    assertEquals "check output for g3" \
        "2" "$(tools_groupToList_SO g3 | wc -l)"
}

test_tools_verify_failsOnMissingMandatoryTools() {
    ___g_tools=( mandatoryTool1=1 mTool2=1 optTool1=0 optTool2=0 )

    scpmocker_patchCommand mTool2
    scpmocker_patchCommand optTool1
    scpmocker_patchCommand optTool2

    tools_verify_SO "${___g_tools[@]}"

    assertEquals "check return value" \
        "$G_RETFAIL" "$?"
}

test_tools_verify_succeedsOnAllMandatoryToolsAvailable() {
    ___g_tools=( mandatoryTool1=1 mTool2=1 optTool1=0 optTool2=0 )
    local verified=()

    scpmocker_patchCommand mandatoryTool1
    scpmocker_patchCommand mTool2
    scpmocker_patchCommand optTool1

    verified=( $(tools_verify_SO "${___g_tools[@]}") )

    assertEquals "check return value" \
        "$G_RETOK" "$?"

    assertEquals "check entry for mandatoryTool1" \
        "mandatoryTool1=1" "${verified[0]}"

    assertEquals "check entry for mTool2" \
        "mTool2=1" "${verified[1]}"

    assertEquals "check entry for optTool1" \
        "optTool1=1" "${verified[2]}"

    assertEquals "check entry for optTool2" \
        "optTool2=0" "${verified[3]}"
}

test_tools_verify_detectsOptionalToolSets() {
    ___g_tools=( "opt1|opt2=0" "opt3|opt4=0" )
    local verified=()

    scpmocker_patchCommand opt1
    scpmocker_patchCommand opt2
    scpmocker_patchCommand opt3

    verified=( $(tools_verify_SO "${___g_tools[@]}") )

    assertEquals "check return value" \
        "$G_RETOK" "$?"

    assertEquals "check entry for opt1" \
        "opt1=1" "${verified[0]}"

    assertEquals "check entry for opt2" \
        "opt2=1" "${verified[1]}"

    assertEquals "check entry for opt3" \
        "opt3=1" "${verified[2]}"

    assertEquals "check entry for opt4" \
        "opt4=0" "${verified[3]}"
}

test_tools_verify_detectsMandatoryToolSets() {
    ___g_tools=( "opt1|opt2=1" "opt3|opt4=1" )
    local verified=()

    scpmocker_patchCommand opt1
    scpmocker_patchCommand opt4

    verified=( $(tools_verify_SO "${___g_tools[@]}") )

    assertEquals "check return value" \
        "$G_RETOK" "$?"

    assertEquals "check entry for opt1" \
        "opt1=1" "${verified[0]}"

    assertEquals "check entry for opt2" \
        "opt2=0" "${verified[1]}"

    assertEquals "check entry for opt3" \
        "opt3=0" "${verified[2]}"

    assertEquals "check entry for opt4" \
        "opt4=1" "${verified[3]}"
}

test_tools_verify_failsOnMandatoryToolsMissingInSet() {
    ___g_tools=( "opt1|opt2=1" "opt3|opt4=1" )

    scpmocker_patchCommand opt1

    tools_verify_SO "${___g_tools[@]}"

    assertEquals "check return value" \
        "$G_RETFAIL" "$?"
}

test_tools_verify_detectsOptionalGroupMembers() {
    ___g_tools=( ngt1=0 ngt2=1 \
        "media:opt1|opt2=1" "media:opt3|opt4=0" )
    local verified=()
    local expected=( "ngt1=0" "ngt2=1" \
       "media:opt1=1" "media:opt2=0" "media:opt3=0" "media:opt4=0" )
    local i=

    scpmocker_patchCommand ngt2
    scpmocker_patchCommand opt1

    verified=( $(tools_verify_SO "${___g_tools[@]}") )

    assertEquals "check return value" \
        "$G_RETOK" "$?"

    for i in "${!verified[@]}"; do
        local entry="${verified[$i]}"
        local expectedEntry="${expected[$i]}"

        assertEquals "checking entry [$i]" \
            "$expectedEntry" "$entry"
    done
}

test_tools_verify_failsOnMandatoryToolsMissingInGroupSet() {
    ___g_tools=( "media:opt1|opt2=1" "media:opt3=0" "media:opt4=1" )

    scpmocker_patchCommand opt1

    tools_verify_SO "${___g_tools[@]}" >/dev/null

    assertEquals "check return value" \
        "$G_RETFAIL" "$?"
}

# shunit call
. shunit2
