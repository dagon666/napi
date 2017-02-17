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
. ../../libs/libnapi_http.sh

setUp() {
    scpmocker_setUp

    # restore original values
    ___g_wget='none'
}

tearDown() {
    scpmocker_tearDown
}

test_http_configure_fallsbackToDefaultWgetInvocation() {
    scpmocker_patchCommand "wget"

    # no print status support
    scpmocker -c wget program

    # no post support
    scpmocker -c wget program -e 1

    http_configure_GV

    assertEquals "check wget command" \
        "0|wget -q -O" "$___g_wget"

    assertEquals "check first mock invocation" \
        "--help" "$(scpmocker -c wget status -A 1)"

    assertEquals "check second mock invocation" \
        "--help" "$(scpmocker -c wget status -A 2)"
}

test_http_configure_detectsServerResponseSupport() {
    scpmocker_patchCommand "wget"

    # print status support
    scpmocker -c wget program -s \
        "-S,  --server-response           print server response."

    # no post support
    scpmocker -c wget program -e 1

    http_configure_GV

    assertEquals "check wget command" \
        "0|wget -q -S -O" "$___g_wget"

    assertEquals "check first mock invocation" \
        "--help" "$(scpmocker -c wget status -A 1)"

    assertEquals "check second mock invocation" \
        "--help" "$(scpmocker -c wget status -A 2)"
}

test_http_configure_detectsPostSupport() {
    scpmocker_patchCommand "wget"

    # print status support
    scpmocker -c wget program -s \
        "-S,  --server-response           print server response."

    # no post support
    scpmocker -c wget program -e 0 -s \
        "--post-data=STRING          use the POST method; send STRING as the data. \
       --post-file=FILE            use the POST method; send contents of FILE."

    http_configure_GV

    assertEquals "check wget command" \
        "1|wget -q -S -O" "$___g_wget"

    assertEquals "check first mock invocation" \
        "--help" "$(scpmocker -c wget status -A 1)"

    assertEquals "check second mock invocation" \
        "--help" "$(scpmocker -c wget status -A 2)"
}

test_http_wget_callsConfiguredCommand() {
    scpmocker_patchCommand "wget"

    ___g_wget="0|wget"
    http_wget

    ___g_wget="123|wget"
    http_wget

    ___g_wget="wget"
    http_wget

    ___g_wget="1111|wget"
    http_wget

    assertEquals "check mock call count" \
        4 "$(scpmocker -c wget status -C)"
}

test_http_isPostRequestSupported_detection() {
    ___g_wget="1|wget"
    assertTrue "check post support" \
        http_isPostRequestSupported

    ___g_wget="0|wget"
    assertFalse "check no post support" \
        http_isPostRequestSupported

    ___g_wget="123|wget"
    assertFalse "check no post support 2" \
        http_isPostRequestSupported
}

test_http_getHttpStatusExtractsStatusFromWgetOutput() {
    local wgetOutput=

    read -d "" wgetOutput << EOF
HTTP/1.1 302 Found
Cache-Control: private
Content-Type: text/html; charset=UTF-8
Location: http://www.google.co.uk/?gfe_rd=cr&ei=jjOnWNWyAcjU8geznrugCQ
Content-Length: 261
Date: Fri, 17 Feb 2017 17:31:58 GMT
HTTP/1.1 200 OK
Date: Fri, 17 Feb 2017 17:31:58 GMT
Expires: -1
Cache-Control: private, max-age=0
Content-Type: text/html; charset=ISO-8859-1
P3P: CP="This is not a P3P policy! See https://www.google.com/support/accounts/answer/151657?hl=en for more info."
Server: gws
X-XSS-Protection: 1; mode=block
X-Frame-Options: SAMEORIGIN
Set-Cookie: NID=97=OkKeQzJpTOAOi5Z2Y4ARk-4s1au-Er-Jas1ym-lfunnKUv2P4G6taMrJAeJQX3dq68IHTp3wxmCr_w_26v9ykdYQt6rllmCdvUXVo4deK2vU3hTDy8ThulGLmbw5dM9o; expires=Sat, 19-Aug-2017 17:31:58 GMT; path=/; domain=.google.co.uk; HttpOnly
Accept-Ranges: none
Vary: Accept-Encoding
Transfer-Encoding: chunked
EOF

    assertEquals "check command output" \
        "302 200" "$(echo "$wgetOutput" | http_getHttpStatus)"
}

test_http_downloadUrl_outputsDataToStdoutAndStatusToStderr() {
    local fakeData="some fake response data"

    scpmocker_patchCommand "wget"
    scpmocker -c wget program -s "$fakeData"

    ___g_wget="1|wget -q -S -O"

    local data=$(http_downloadUrl_SOSE \
        "http://some.fake.url")

    assertEquals "check command output" \
        "$fakeData" "$data"

    assertEquals "check mock call count" \
        1 "$(scpmocker -c wget status -C)"
}

test_http_downloadUrl_handlesPostRequests() {
    local fakeData="some fake response data"
    local postData="some post data"
    local fakeUrl="http://some.fake.url"

    scpmocker_patchCommand "wget"
    scpmocker -c wget program -s "$fakeData"

    ___g_wget="1|wget -q -S -O"

    local data=$(http_downloadUrl_SOSE \
        "$fakeUrl" "" "$postData")

    assertEquals "checking mock positionals" \
        "-q -S -O /dev/stdout --post-data=${postData} $fakeUrl" \
        "$(scpmocker -c wget status -A 1)"
}


# shunit call
. shunit2
