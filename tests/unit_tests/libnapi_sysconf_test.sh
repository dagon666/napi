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

# fakes/mocks
. fake/libnapi_logging_mock.sh

# module under test
. ../../libs/libnapi_sysconf.sh

#
# tests env setup
#
setUp() {
    ___g_sysconf_configuration=()
}

#
# tests env tear down
#
tearDown() {
    ___g_sysconf_configuration=()
}

test_sysconf_getKey_SO_returnsValueForExistingKey() {
    local key="some_key"
    local value="some value"
    ___g_sysconf_configuration=( "${key}=${value}" )

    assertEquals 'check the key value' \
        "$value" "$(sysconf_getKey_SO "$key")"

    assertEquals 'check return status on success' \
        0 $?
}

test_sysconf_getKey_SO_returnsValueStartingWithDelimiter() {
    local key="some_key"
    local value="===some value"
    ___g_sysconf_configuration=( "${key}=${value}" )

    assertEquals 'check the key value' \
        "$value" "$(sysconf_getKey_SO "$key")"

    assertEquals 'check return status on success' \
        0 $?
}

test_sysconf_getKey_SO_failsForNonExistingKey() {
    local key="some_key"
    local value="some value"
    ___g_sysconf_configuration=( "${key}=${value}" )

    local returnValue=
    returnValue="$(sysconf_getKey_SO "non-existingKey")"

    assertEquals 'check return status on failure' \
        "$G_RETFAIL" $?

    assertNotEquals 'check the key value' \
        "$value" "$returnValue"
}

test_sysconf_setKey_GV_addsValuesWithWhiteCharacters() {
    local key="someKey"
    local value="some value with white characters"

    sysconf_setKey_GV "$key" "$value"

    assertEquals 0 $?

    assertEquals \
        "${key}=${value}" "${___g_sysconf_configuration[*]}"

    assertEquals 'check the key value' \
        "$value" "$(sysconf_getKey_SO "$key")"
}

test_sysconf_setKey_GV_modifiesAlreadyExistingKey() {
    local key="someKey"
    local originalValue="original-value"
    local value="some value with white characters"

    sysconf_setKey_GV "$key" "$originalValue"

    sysconf_setKey_GV "$key" "$value"

    assertEquals 0 $?

    assertNotEquals \
        "$originalValue" "$(sysconf_getKey_SO "$key")"

    assertEquals \
        "${key}=${value}" "${___g_sysconf_configuration[*]}"

    assertEquals 'check the key value' \
        "$value" "$(sysconf_getKey_SO "$key")"
}

# shunit call
. shunit2
