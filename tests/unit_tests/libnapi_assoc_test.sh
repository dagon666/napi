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
. fake/libnapi_logging_mock.sh

# module under test
. ../../libs/libnapi_assoc.sh

test_assoc_getKey_SO_extractsKeyValueWithoutDelimiter() {
    local fn='key====value'
    local key=$(assoc_getKey_SO "$fn")

    assertEquals 'check if the key matches' \
        'key' "$key"
}

test_assoc_getKey_SO_failsForIncorrectKey() {
    local fn='===key=value'
    local key=

    key=$(assoc_getKey_SO "$fn")
    assertEquals 'check if the key empty' \
        '' "$key"
}

test_assoc_getValue_SO_treatsExtraDelimitersAsPartOfValue() {
    local fn='key====value'
    local value=$(assoc_getValue_SO "$fn")

    assertEquals 'check if the value matches' \
        '===value' "$value"
}

test_assoc_getValue_SO_extractsAssociatedKeyValue() {
    local fn='key=value'
    local key=$(assoc_getKey_SO "$fn")
    local value=$(assoc_getValue_SO "$fn")

    assertEquals 'check if the key matches' \
        'key' "$key"
    assertEquals 'check if the value matcher' \
        'value' "$value"
}

test_assoc_getGroup_SO_extractsAssociatedGroup() {
    local group='group'
    local fn="${group}:irrelevant key=irrelevant value"

    assertEquals 'check extracted group value' \
        "$group" "$(assoc_getGroup_SO "$fn")"
}

test_assoc_getGroup_SO_failsForInvalidGroupName() {
    local group=':group'
    local fn="${group}:irrelevant key=irrelevant value"

    assertEquals 'check extracted group value is empty' \
        "" "$(assoc_getGroup_SO "$fn")"
}

test_assoc_getGroup_SO_treatsExtraDelimitersAsPartOfKey() {
    local group='group'
    local key=':::irrelevant key'
    local fn="${group}:${key}=irrelevant value"

    assertEquals "check that group value doesn't contain extra delimiters" \
        "$group" "$(assoc_getGroup_SO "$fn")"

    assertEquals "check key contains extra group delimiters" \
        "$key" "$(assoc_getKey_SO "$fn")"
}

test_assoc_lookupValueSO_findsKeyValues() {
    local arr=( key1=value1 key2=value2 a=b x=123 )
    local v=''
    local s=0

    assertEquals 'looking up value - array' \
        123 "$(assoc_lookupValue_SO 'x' "${arr[@]}" )"

    v=$(assoc_lookupValue_SO 'not_existing' "${arr[@]}" )
    assertEquals 'return value' $G_RETFAIL "$?"

    v=$(assoc_lookupValue_SO 'not existing' "${arr[@]}" )
    assertEquals 'function output for non-existing key' \
        "" "$v"
}

test_assoc_lookupKey_SO_findsTheKeyIndex() {
    local arr=( "key1=value1" "key2=value2" "a=b" "x=123" )

    assertEquals 'looking up key1' \
        0 "$(assoc_lookupKey_SO 'key1' "${arr[@]}" )"

    assertEquals 'looking up key2' \
        1 "$(assoc_lookupKey_SO 'key2' "${arr[@]}" )"

    assertEquals 'looking up a' \
        2 "$(assoc_lookupKey_SO 'a' "${arr[@]}" )"

    assertEquals 'looking up x' \
        3 "$(assoc_lookupKey_SO 'x' "${arr[@]}" )"
}

test_assoc_lookupKey_SO_failsForNonExistingKey() {
    local arr=( key1=value1 key2=value2 a=b x=123 )
    local keyIdx=0
    local i=0

    for i in {0..10}; do
        local key="non-existing-key-${i}"
        keyIdx="$(assoc_lookupKey_SO "$key" "${arr[@]}" )"

        assertEquals "check return status for key ${key}" \
            $G_RETFAIL $?

        assertEquals "looking up ${key}" \
            -1 "$keyIdx"
    done
}

test_assoc_modifyValue_SO_addsValueIfItDoesntExist() {
    local testArray=( 'key1=value' 'group:key2=value2' )
    local newKey='newKey'
    local newValue="newValue"
    local output=( $(assoc_modifyValue_SO \
        "$newKey" \
        "$newValue" \
        "${testArray[@]}") )

    local newKeyIdx="$(assoc_lookupKey_SO "$newKey" "${output[@]}")"

    assertEquals "check return status from key lookup" \
        0 $?

    assertNotEquals "check key index not out of bound" \
        -1 "$newKeyIdx"

    assertEquals "check if adds value if it doesn't exist" \
        "$newValue" "$(assoc_lookupValue_SO "$newKey" "${output[@]}")"
}

test_assoc_modifyValue_SO_modifiesAlreadyExistingKey() {
    local testArray=( 'key1=value' 'group:key2=value2' )
    local key='key1'
    local newValue="newValue"
    local output=( $(assoc_modifyValue_SO \
        "$key" \
        "$newValue" \
        "${testArray[@]}") )

    local keyIdx="$(assoc_lookupKey_SO "$key" "${output[@]}")"

    assertEquals "check return status from key lookup" \
        0 $?

    assertNotEquals "check key index not out of bound" \
        -1 "$keyIdx"

    assertEquals "check if adds value if modifies existing key" \
        "$newValue" "$(assoc_lookupValue_SO "$key" "${output[@]}")"
}

test_assoc_modifyValue_SO_maintainsTheGroup() {
    local key='key2'
    local originalGroup="group"
    local originalValue="original_value"
    local newValue="new_key_value"

    local testArray=( 'key1=value' \
        "${originalGroup}:${key}=${originalValue}")

    local output=( $(assoc_modifyValue_SO \
        "$key" \
        "$newValue" \
        "${testArray[@]}") )

    local originalGroup1="$(assoc_lookupKeysGroup_SO \
        "$key" "${output[@]}")"

    assertEquals "check return value from key lookup" \
        0 $?

    assertEquals "check if group remains the same" \
        "$originalGroup" "$originalGroup1"

    assertEquals "check if adds value if it doesnt exist" \
        "$newValue" "$(assoc_lookupValue_SO "$key" "${output[@]}")"
}

test_assoc_modifyValue_GV_modifiesGlobalArrays() {
    local key='key'
    local value='value'
    local newValue='new value'
    declare -a globalArray=( "${key}=${value}" )
    local expected=( "${key}=${newValue}" )

    assoc_modifyValue_GV "$key" "$newValue" "globalArray"

    assertEquals "check return status" \
        $G_RETOK $?

    assertEquals "check the array contents" \
        "${expected[*]}" "${globalArray[*]}"
}

test_assoc_modifyValue_GV_addsKeyIfItDoesntExist() {
    local newKey='newKey'
    local newValue='new value'
    declare -a globalArray=( "key=value" )
    local expected=( "${globalArray[@]}" "${newKey}=${newValue}" )

    assoc_modifyValue_GV "$newKey" "$newValue" "globalArray"

    assertEquals "check return status" \
        $G_RETOK $?

    assertEquals "check the array contents" \
        "${expected[*]}" "${globalArray[*]}"
}

test_assoc_modifyValue_GV_maintainsTheGroup() {
    local group='group'
    local key='newKey'
    local value='value'
    local newValue='new value'
    declare -a globalArray=( "${group}:${key}=${value}" )
    local expected=( "${group}:${key}=${newValue}" )

    assoc_modifyValue_GV "$key" "$newValue" "globalArray"

    assertEquals "check return status" \
        $G_RETOK $?

    assertEquals "check the array contents" \
        "${expected[*]}" "${globalArray[*]}"
}

test_assoc_getKvPair_SO_extractsKvPairsWithGroups() {
    local entries=( 'group1:key=value' \
        'group2:k2=v2' \
        'group2:k3=v3' \
        'group3:k4=v4' \
        )

    local pairs=( 'key=value' \
        'k2=v2' \
        'k3=v3' \
        'k4=v4' \
        )

    local i=
    local p=
    for i in "${!entries[@]}"; do

        p="$(assoc_getKvPair_SO "${entries[$i]}")"

        assertEquals "checking return value" \
            $G_RETOK $?

        assertEquals "checking pair at position [$i]" \
            "${pairs[$i]}" "$p"
    done
}

test_assoc_getKvPair_SO_extractsKvPairsWithoutGroups() {
    local entries=( 'key=value' \
        'k2=v2' \
        'k3=v3' \
        'k4=v4' \
        )

    local pairs=( 'key=value' \
        'k2=v2' \
        'k3=v3' \
        'k4=v4' \
        )

    local i=
    local p=
    for i in "${!entries[@]}"; do
        p="$(assoc_getKvPair_SO "${entries[$i]}")"

        assertEquals "checking return value" \
            $G_RETOK $?

        assertEquals "checking pair at position [$i]" \
            "${pairs[$i]}" "$p"
    done
}

test_assoc_getKvPair_SO_treatsExtraDelimitersAsPartOfKv() {
    local entries=( 'group1::::key=value' \
        'group2:::k2=v2' \
        'group2::::k3=v3' \
        'group3::k4=v4' \
        )

    local pairs=( ':::key=value' \
        '::k2=v2' \
        ':::k3=v3' \
        ':k4=v4' \
        )

    local i=
    local p=
    for i in "${!entries[@]}"; do

        p="$(assoc_getKvPair_SO "${entries[$i]}")"

        assertEquals "checking return value" \
            $G_RETOK $?

        assertEquals "checking pair at position [$i]" \
            "${pairs[$i]}" "$p"
    done
}

test_assoc_lookupGroupKv_SO_findsAllKvEntriesForGivenGroup() {
    local entries=( 'group1:key=value' \
        'group2:k2=v2' \
        'group2:k3=v3' \
        'group3:k4=v4' \
        )

    assertEquals "checking group1" \
        "key=value" "$(assoc_lookupGroupKv_SO 'group1' "${entries[@]}")"

    assertEquals "checking group2" \
        "k2=v2 k3=v3" "$(assoc_lookupGroupKv_SO 'group2' "${entries[@]}")"

    assertEquals "checking group3" \
        "k4=v4" "$(assoc_lookupGroupKv_SO 'group3' "${entries[@]}")"
}

test_assoc_lookupGroupKv_SO_returnsNoResultsIfGroupDoesntExist() {
    local entries=( 'group1:key=value' \
        'group2:k2=v2' \
        'group2:k3=v3' \
        'group3:k4=v4' \
        )

    assertNull "checking non existing group 4" \
        "$(assoc_lookupGroupKv_SO 'group4' "${entries[@]}")"
}

test_assoc_lookupGroupKeys_SO_returnsAllGroupKeys() {
    local entries=( 'group1:key=value' \
        'group2:k2=v2' \
        'group2:k3=v3' \
        'group3:k4=v4' \
        )

    assertEquals 'checking for group1 keys' \
        "key" "$(assoc_lookupGroupKeys_SO 'group1' "${entries[@]}")"

    assertEquals 'checking for group2 keys' \
        "k2 k3" "$(assoc_lookupGroupKeys_SO 'group2' "${entries[@]}")"

    assertEquals 'checking for group3 keys' \
        "k4" "$(assoc_lookupGroupKeys_SO 'group3' "${entries[@]}")"
}

test_assoc_lookupKeysGroup_SO_extractsKeysGroup() {
    local entries=( 'group1:key=value' \
        'group2:k2=v2' \
        'group2:k3=v3' \
        'group3:k4=v4' \
        'k5=v6'
        )

    assertEquals 'checking for group of: key' \
        'group1' "$(assoc_lookupKeysGroup_SO 'key' "${entries[@]}")"

    assertEquals 'checking for group of: k2' \
        'group2' "$(assoc_lookupKeysGroup_SO 'k2' "${entries[@]}")"

    assertEquals 'checking for group of: k3' \
        'group2' "$(assoc_lookupKeysGroup_SO 'k3' "${entries[@]}")"

    assertEquals 'checking for group of: k4' \
        'group3' "$(assoc_lookupKeysGroup_SO 'k4' "${entries[@]}")"

    assertNull 'checking for group of: k5' \
        "$(assoc_lookupKeysGroup_SO 'k5' "${entries[@]}")"
}

# shunit call
. shunit2
