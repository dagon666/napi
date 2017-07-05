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
. ../../libs/libnapi_assoc.sh
. ../../libs/libnapi_retvals.sh
. ../../libs/libnapi_wrappers.sh

# fakes/mocks
. fake/libnapi_logging_fake.sh
. mock/scpmocker.sh

# module under test
. ../../libs/libnapi_subotage.sh

#
# tests env setup
#
setUp() {
    # restore original values
    ___g_subotageLastingTimeMs=3000
    scpmocker_setUp
}

#
# tests env tear down
#
tearDown() {
    scpmocker_tearDown
}


test_subotage_isFormatSupportedValidatesSupportedFormats() {
    local validFormats=( "microdvd" "mpl2" "subrip" \
        "subviewer2" "tmplayer" )
    local invalidFormats=( "made-up" "other" "abc" "def" )
    local fmt=

    for fmt in "${validFormats[@]}"; do
        subotage_isFormatSupported "$fmt"
        assertTrue "check return value for format [$fmt]" \
            "$?"
    done

    for fmt in "${invalidFormats[@]}"; do
        subotage_isFormatSupported "$fmt"
        assertFalse "check return value for format [$fmt]" \
            "$?"
    done
}

# shunit call
. shunit2
