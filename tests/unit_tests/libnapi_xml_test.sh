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

# fakes/mocks
. fake/libnapi_logging_fake.sh

# module under test
. ../../libs/libnapi_xml.sh

#
# tests env setup
#
setUp() {

    # restore original values
    ___g_subs_defaultExtension='txt'
}

#
# tests env tear down
#
tearDown() {
    :
}

test_xml_extractXmlTag() {
    local contents=( "" \
       "<othertag>nested tag contents</othertag>" \
      '<t1><t2><t3><t4 id="some arguments">data</t4></t3></t2></t1>' )

    local extracted=
    local tag=
    local targetTag=

    tag="<tag>text contents for the tag</tag>"
    targetTag="$tag"
    extracted=$(echo "$tag" | \
        xml_extractXmlTag "tag")
    assertEquals "check output for outer most tag" \
        "$targetTag" "$extracted"

    targetTag="<nested>text contents for the tag</nested>"
    tag="<tag>${targetTag}</tag>"
    extracted=$(echo "$tag" | \
        xml_extractXmlTag "nested")

    assertEquals "check output for inner most tag" \
        "$targetTag" "$extracted"

    targetTag="<nested>text contents for the tag</nested>"
    tag="<tag id=\"some attribute\">${targetTag}</tag>"
    extracted=$(echo "$tag" | \
        xml_extractXmlTag "nested")

    assertEquals "check output for inner most tag (outer most has attributes)" \
        "$targetTag" "$extracted"

    targetTag="<nested>text contents for the tag</nested>"
    tag="<tag id=\"some attribute\"><t2><t3><t4><t5>${targetTag}</t5></t4></t3></t2></tag>"
    extracted=$(echo "$tag" | \
        xml_extractXmlTag "nested")

    assertEquals "check output for deep hierarchy" \
        "$targetTag" "$extracted"
}

test_xml_extractCdataTag_behavior() {
    local data="This is some arbitrary cdata content"
    local extracted=$(echo "![CDATA[$data]]" | xml_extractCdataTag)

    assertEquals "check the data extracted" \
        "$data" "$extracted"

    local base64Payload=$(echo "$data" | base64)
    extracted=$(echo "![CDATA[$base64Payload]]" | xml_extractCdataTag)

    assertEquals "check the base64 data extracted" \
        "$base64Payload" "$extracted"
}

test_xml_stripXmlTag() {
    local tags="<t1><t2><t3><t4></t4></t3></t2></t1>"
    local data="some non-tag data"
    local cdata="![CDATA[${data}]]"

    local outermost="<tag>${data}</tag>"
    local stripped=$(echo "$outermost" | xml_stripXmlTag)

    assertEquals "check stripped output for raw data" \
        "$data" "$stripped"

    outermost="<tag>${cdata}</tag>"
    stripped=$(echo "$outermost" | xml_stripXmlTag)
    assertEquals "check stripped output for cdata" \
        "$cdata" "$stripped"

    outermost="<tag>${tags}</tag>"
    stripped=$(echo "$outermost" | xml_stripXmlTag)
    assertEquals "produces empty output for embedded tags" \
        "" "$stripped"
}

# shunit call
. shunit2
