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
. ../../libs/libnapi_constants.sh

# fakes/mocks
. fake/libnapi_fs_fake.sh
. fake/libnapi_logging_fake.sh
. fake/libnapi_version_fake.sh
. mock/scpmocker.sh

# module under test
. ../../libs/libnapi_napiprojekt.sh

setUp() {
    scpmocker_setUp

    # restore original values
    ___g_napiprojektCredentials=( '' '' )
    ___g_napiprojekt_napiprojektId='NapiProjektPython'
}

tearDown() {
    scpmocker_tearDown
}

test_napiprojekt_is7zRequired_inspectsGvValue() {
    local values=( 'other' 'NapiProjektPython' 'NapiProjekt' 'pynapi' )
    local isRequired=( 0 0 0 1 )

    local value=
    local v=

    for v in "${!values[@]}"; do
        value="${values[$v]}"
        ___g_napiprojekt_napiprojektId="$value"
        _napiprojekt_is7zRequired
        assertEquals "check return value for $value" \
            "${isRequired[$v]}" "$?"
    done
}

test_napiprojekt_verifyNapiprojektId_verifiesIdsProperly() {
    local values=( 'other' 'NapiProjektPython' 'NapiProjekt' 'pynapi' \
        'some other' 'unknown' 'xxx' )
    local validationResult=( $G_RETOK $G_RETOK $G_RETOK $G_RETOK \
       $G_RETPARAM $G_RETPARAM $G_RETPARAM )

    local value=
    local v=

    for v in "${!values[@]}"; do
        value="${values[$v]}"
        ___g_napiprojekt_napiprojektId="$value"
        _napiprojekt_verifyNapiprojektId
        assertEquals "check return value for $value" \
            "${validationResult[$v]}" "$?"
    done
}

test_napiprojekt_verifyNapiprojektCredentials() {
    local status=0

    ___g_napiprojektCredentials=( '' '' )
    _napiprojekt_verifyNapiprojektCredentials
    assertEquals 'success on lack of parameters' $G_RETOK $?

    ___g_napiprojektCredentials=( 'some user' '' )
    _napiprojekt_verifyNapiprojektCredentials
    assertEquals 'failure on lack of password' $G_RETPARAM $?

    ___g_napiprojektCredentials=( '' 'some password' )
    _napiprojekt_verifyNapiprojektCredentials
    assertEquals 'failure on lack of password' $G_RETPARAM $?

    ___g_napiprojektCredentials=( 'some user' 'some password' )
    _napiprojekt_verifyNapiprojektCredentials
    assertEquals 'success when both parameters provided' $G_RETOK $?
}

test_napiprojekt_verifyArguments_resetsCredentials() {
    scpmocker_patchFunction fs_is7zAvailable

    ___g_napiprojektCredentials=( 'some user' '' )
    napiprojekt_verifyArguments_GV
    assertNull "empty password - check for empty user name" \
        "${___g_napiprojektCredentials[0]}"
    assertNull "empty password - check for empty user password" \
        "${___g_napiprojektCredentials[1]}"

    ___g_napiprojektCredentials=( '' 'some password' )
    napiprojekt_verifyArguments_GV
    assertNull "empty user name - check for empty user name" \
        "${___g_napiprojektCredentials[0]}"
    assertNull "empty user name - check for empty user password" \
        "${___g_napiprojektCredentials[1]}"

    scpmocker_resetFunction fs_is7zAvailable
}

test_napiprojekt_verifyArguments_restoresLegacy() {
    ___g_napiprojekt_napiprojektId="other"
    scpmocker_patchFunction fs_is7zAvailable
    scpmocker -c func_fs_is7zAvailable program -e 1

    napiprojekt_verifyArguments_GV
    assertEquals "check for legacy mode" \
        "pynapi" "$___g_napiprojekt_napiprojektId"

    scpmocker_resetFunction fs_is7zAvailable
    assertEquals "check mock call count" \
        1 "$(scpmocker -c func_fs_is7zAvailable status -C)"
}

test_napiprojekt_verifyArguments_doesntRestoreLegacyIfNotNeeded() {
    local values=( 'other' 'NapiProjektPython' 'NapiProjekt' 'pynapi' )
    local v=

    scpmocker_patchFunction fs_is7zAvailable

    for v in "${values[@]}"; do
        scpmocker -c func_fs_is7zAvailable program -e 0

        ___g_napiprojekt_napiprojektId="$v"
        napiprojekt_verifyArguments_GV

        assertEquals "check for legacy non-legacy mode" \
            "$v" "$___g_napiprojekt_napiprojektId"
    done

    scpmocker_resetFunction fs_is7zAvailable
    assertTrue "check mock call count" \
        "[ 1 -lt $(scpmocker -c func_fs_is7zAvailable status -C) ]"
}

test_napiprojekt_setNapiprojektId_setsTheGlobalOrFallsBack() {
    local good=( 'other' 'NapiProjektPython' 'NapiProjekt' 'pynapi' )
    local bad=( 'bollocks' 'crap' )
    local v=

    for v in "${good[@]}"; do
        napiprojekt_setNapiprojektId_GV "$v"

        assertEquals "checking good value $v" \
            "$v" "$___g_napiprojekt_napiprojektId"
    done

    for v in "${bad[@]}"; do
        napiprojekt_setNapiprojektId_GV "$v"

        assertEquals "checking bad value $v" \
            "pynapi" "$___g_napiprojekt_napiprojektId"
    done
}

test_napiprojekt_isNapiprojektIdLegacy() {
    local ids=( 'other' 'NapiProjektPython' 'NapiProjekt' 'pynapi' )
    local results=( 0 1 1 0 )
    local v=

    for v in "${!ids[@]}"; do
        local id="${ids[$v]}"

        ___g_napiprojekt_napiprojektId="$id"
        napiprojekt_isNapiprojektIdLegacy

        assertEquals "check return value for $id" \
            "${results[$v]}" $?
    done

    for v in "${bad[@]}"; do
        napiprojekt_setNapiprojektId_GV "$v"

        assertEquals "checking bad value $v" \
            "pynapi" "$___g_napiprojekt_napiprojektId"
    done
}

test_napiprojekt_setNapiprojektUserNamePassword() {
    local u="some username"
    local p="some password"

    assertNull "check user name null" \
        "${___g_napiprojektCredentials[0]}"

    assertNull "check password null" \
        "${___g_napiprojektCredentials[1]}"

    napiprojekt_setNapiprojektUserName_GV "$u"
    napiprojekt_setNapiprojektPassword_GV "$p"

    assertEquals "check user name" \
        "$u" "${___g_napiprojektCredentials[0]}"

    assertEquals "check password" \
        "$p" "${___g_napiprojektCredentials[1]}"
}

test_napiprojekt_f_calculatesCorrectHash() {
	local sum="91a929824737bbdd98c41e17d7f9630c"
	local h="ae34b"
	local output=''

	output=$(napiprojekt_f_SO "$sum")
	assertEquals "verifying hash" \
        "$h" "$output"
}

test_napiprojekt_normalizeHash_normalizesTheHashCaseness() {
    local hashes=( napiprojekt:91a929824737bbdd98c41e17d7f9630 \
        napiprojekt:c91A929824737BBDD98C41E17D7F9630C \
        DEADBEEF \
        beefdead00123  )
    local expected=( 91a929824737bbdd98c41e17d7f9630 \
        c91a929824737bbdd98c41e17d7f9630c \
        deadbeef \
        beefdead00123  )
    local normalizedHash=

    for h in "${!hashes[@]}"; do
        normalizedHash=$(napiprojekt_normalizeHash_SO "${hashes[$h]}")
        assertEquals "check normalized value index $h" \
            "${expected[$h]}" "$normalizedHash"
    done
}

test_napiprojekt_f_calculateMd5VideoFile_calculatesHashesForVideoFiles() {
    local f=
    local calculatedMd5=
    local expectedMd5=

    for f in "${NAPITESTER_TESTDATA}/testdata/media/"*; do
        expectedMd5=$(dd if="$f" bs=1024k count=10 2> /dev/null |\
            md5sum |\
            cut -d ' ' -f 1)

        calculatedMd5=$(napiprojekt_calculateMd5VideoFile_SO "$f")

        assertEquals "check md5 for [$f]" \
            "$expectedMd5" "$calculatedMd5"
    done
}

tests_napiprojekt_downloadXml_attemptsMode17IfNoFileDetailsProvided() {
    local h="1234567890"
    local xml=$(mktemp -p "${SHUNIT_TMPDIR}")
    local url="${g_napiprojektBaseUrl}${g_napiprojektApi3Uri}"
    local lang="SOMELANG"
    local expectedData=
    local expectedArgv=


    scpmocker_patchFunction http_downloadUrl_SOSE
    scpmocker -c func_http_downloadUrl_SOSE program -e 0

    napiprojekt_downloadXml "$h" "" "0" "$xml" "$lang"

    scpmocker_resetFunction http_downloadUrl_SOSE

    expectedData="mode=17"
    expectedData="${expectedData}&client=${___g_napiprojekt_napiprojektId}"
    expectedData="${expectedData}&client_ver=${g_napiprojektClientVersion}"
    expectedData="${expectedData}&user_nick=${___g_napiprojektCredentials[0]}"
    expectedData="${expectedData}&user_password=${___g_napiprojektCredentials[1]}"
    expectedData="${expectedData}&downloaded_subtitles_id=${h}"
    expectedData="${expectedData}&downloaded_subtitles_lang=${lang}"
    expectedData="${expectedData}&the=end"
    expectedArgv="${url} ${xml} ${expectedData}"

    assertEquals "check mock's argv" \
        "$expectedArgv" "$(scpmocker -c func_http_downloadUrl_SOSE status -A 1)"
}

tests_napiprojekt_downloadXml_attemptsMode31IfFileDetailsProvided() {
    local h="1234567890"
    local movieName="some movie filename.avi"
    local movieFileSize="112233"
    local xml=$(mktemp -p "${SHUNIT_TMPDIR}")
    local url="${g_napiprojektBaseUrl}${g_napiprojektApi3Uri}"
    local lang="SOMELANG"
    local expectedData=
    local expectedArgv=

    ___g_napiprojektCredentials=( 'some username' 'some password' )

    scpmocker_patchFunction http_downloadUrl_SOSE
    scpmocker -c func_http_downloadUrl_SOSE program -e 0

    napiprojekt_downloadXml "$h" "$movieName" "$movieFileSize" "$xml" "$lang"

    scpmocker_resetFunction http_downloadUrl_SOSE

    expectedData="mode=31"
    expectedData="${expectedData}&client=${___g_napiprojekt_napiprojektId}"
    expectedData="${expectedData}&client_ver=${g_napiprojektClientVersion}"
    expectedData="${expectedData}&user_nick=${___g_napiprojektCredentials[0]}"
    expectedData="${expectedData}&user_password=${___g_napiprojektCredentials[1]}"
    expectedData="${expectedData}&downloaded_subtitles_id=${h}"
    expectedData="${expectedData}&downloaded_subtitles_lang=${lang}"

    expectedData="${expectedData}&downloaded_cover_id=${h}"
    expectedData="${expectedData}&advert_type=flashAllowed"
    expectedData="${expectedData}&video_info_hash=${h}"
    expectedData="${expectedData}&nazwa_pliku=${movieName}"
    expectedData="${expectedData}&rozmiar_pliku_bajty=${movieFileSize}"
    expectedData="${expectedData}&the=end"
    expectedArgv="${url} ${xml} ${expectedData}"

    assertEquals "check mock's argv" \
        "$expectedArgv" "$(scpmocker -c func_http_downloadUrl_SOSE status -A 1)"
}

tests_napiprojekt_downloadXml_failsIfDownloadFails() {
    local h="1234567890"
    local xml=$(mktemp -p "${SHUNIT_TMPDIR}")

    scpmocker_patchFunction http_downloadUrl_SOSE
    scpmocker -c func_http_downloadUrl_SOSE program -e 1

    napiprojekt_downloadXml "$h" "" "0" "$xml"

    assertEquals "check return status" \
        "$G_RETFAIL" "$?"

    scpmocker_resetFunction http_downloadUrl_SOSE
}

test_napiprojekt_verifyXml() {
    napiprojekt_verifyXml "${NAPITESTER_TESTDATA}/testdata/xml/example.xml"
    assertTrue "check return value" \
        $?
}

test_napiprojekt_verifyXml_failsForEmptyAndNonExistingFiles() {
    local xml=$(mktemp -p "${SHUNIT_TMPDIR}")

    napiprojekt_verifyXml "$xml"
    assertFalse "check return value" $?

    napiprojekt_verifyXml "/this/path/doesnt/exist"
    assertFalse "check return value" $?
}

test_napiprojekt_extractSubsFromXml_failsOnStatusFailure() {
    scpmocker_patchFunction xml_extractXmlTag
    scpmocker -c func_xml_extractXmlTag program -s "error"

    napiprojekt_extractSubsFromXml "xml path" "subs path"
    assertEquals "check rv" \
        "$G_RETUNAV" "$?"

    scpmocker_resetFunction xml_extractXmlTag
}

test_napiprojekt_extractSubsFromXml_failsOnLackOfSubtitlesTag() {
    scpmocker_patchFunction xml_extractXmlTag
    scpmocker -c func_xml_extractXmlTag program -s "success"
    scpmocker -c func_xml_extractXmlTag program -s ""

    napiprojekt_extractSubsFromXml "xml path" "subs path"
    assertEquals "check rv" \
        "$G_RETUNAV" "$?"

    scpmocker_resetFunction xml_extractXmlTag
}

test_napiprojekt_extractSubsFromXml_successfullyExtractsSubs() {
    local subsPath="$(mktemp -p "${SHUNIT_TMPDIR}")"
    local xmlPath="$(mktemp -p "${SHUNIT_TMPDIR}")"
    local tmpArchive="$(mktemp -p "${SHUNIT_TMPDIR}")"
    local tmp7zArchive="${SHUNIT_TMPDIR}/archive.7z"

    local exampleSubs="some example subtitles extracted from xml"

    # create the test archive
    echo "$exampleSubs" | \
        7z a -t7z -si -p"${g_napiprojektPassword}" "$tmp7zArchive" >/dev/null

    local exampleSubsBase64="$(base64 "$tmp7zArchive")"
    local contentTag="![CDATA[${exampleSubsBase64}]]"

    scpmocker_patchFunction xml_extractXmlTag
    scpmocker_patchFunction fs_mktempFile_SO
    scpmocker_patchFunction xml_extractCdataTag

    scpmocker -c func_xml_extractXmlTag program -s "success"
    scpmocker -c func_xml_extractXmlTag program -s "$contentTag"
    scpmocker -c func_xml_extractCdataTag program -s "$exampleSubsBase64"
    scpmocker -c func_fs_mktempFile_SO program -s "${tmpArchive}"

    napiprojekt_extractSubsFromXml "$xmlPath" "$subsPath"
    assertEquals "check rv" \
        "$G_RETOK" "$?"

    assertEquals "check file contents" \
        "$exampleSubs" "$(<${subsPath})"

    scpmocker_resetFunction xml_extractXmlTag
    scpmocker_resetFunction fs_mktempFile_SO
    scpmocker_resetFunction xml_extractCdataTag
}

test_napiprojekt_extractCoverFromXml_failsOnStatusFailure() {
    scpmocker_patchFunction xml_extractXmlTag
    scpmocker -c func_xml_extractXmlTag program -s "error"

    napiprojekt_extractCoverFromXml "xml path" "subs path"
    assertEquals "check rv" \
        "$G_RETUNAV" "$?"

    scpmocker_resetFunction xml_extractXmlTag
}

test_napiprojekt_extractCoverFromXml_failsOnLackOfCoverTag() {
    scpmocker_patchFunction xml_extractXmlTag
    scpmocker -c func_xml_extractXmlTag program -s "success"
    scpmocker -c func_xml_extractXmlTag program -s ""

    napiprojekt_extractCoverFromXml "xml path" "subs path"
    assertEquals "check rv" \
        "$G_RETUNAV" "$?"

    scpmocker_resetFunction xml_extractXmlTag
}

test_napiprojekt_extractCoverFromXml_successfullyExtractsCover() {
    local coverPath="$(mktemp -p "${SHUNIT_TMPDIR}")"
    local xmlPath="$(mktemp -p "${SHUNIT_TMPDIR}")"

    local exampleCover="This is cover data"
    local exampleCoverBase64="$(echo "$exampleCover" | base64)"
    local coverTag="![CDATA[${exampleCoverBase64}]]"

    scpmocker_patchFunction xml_extractXmlTag
    scpmocker_patchFunction xml_extractCdataTag

    scpmocker -c func_xml_extractXmlTag program -s "success"
    scpmocker -c func_xml_extractXmlTag program -s "$coverTag"
    scpmocker -c func_xml_extractCdataTag program -s "$exampleCoverBase64"

    napiprojekt_extractCoverFromXml "$xmlPath" "$coverPath"
    assertEquals "check rv" \
        "$G_RETOK" "$?"

    assertEquals "check contents" \
        "$exampleCover" "$(<${coverPath})"

    scpmocker_resetFunction xml_extractXmlTag
    scpmocker_resetFunction xml_extractCdataTag
}

test_napiprojekt_extractNfoFromXml_failsOnStatusFailure() {
    scpmocker_patchFunction xml_extractXmlTag
    scpmocker -c func_xml_extractXmlTag program -s "error"

    napiprojekt_extractNfoFromXml "xml path" "subs path"
    assertEquals "check rv" \
        "$G_RETUNAV" "$?"

    scpmocker_resetFunction xml_extractXmlTag
}

test_napiprojekt_extractNfoFromXml_worksCorrectly() {
    local xmlPath="some xml file"
    local nfoPath="$(mktemp -p "${SHUNIT_TMPDIR}")"
    local i=

    scpmocker_patchFunction xml_extractXmlTag
    scpmocker_patchFunction xml_stripXmlTag
    scpmocker_patchFunction xml_extractCdataTag

    scpmocker -c func_xml_extractXmlTag program -s "success"
    scpmocker -c func_xml_extractXmlTag program -s "subtitles tag"
    scpmocker -c func_xml_extractXmlTag program -s "movie tag"

    for i in {1..64}; do
        scpmocker -c func_xml_extractXmlTag program -s "tag data ${i}"
    done

    napiprojekt_extractNfoFromXml "${xmlPath}" "${nfoPath}"

    assertEquals "check return value" \
        "$G_RETOK" "$?"

    scpmocker_resetFunction xml_extractCdataTag
    scpmocker_resetFunction xml_stripXmlTag
    scpmocker_resetFunction xml_extractXmlTag
}

test_napiprojekt_extractTitleFromXml_failsOnXmlStatusFailure() {
    scpmocker_patchFunction xml_extractXmlTag
    scpmocker -c func_xml_extractXmlTag program -s "error"

    napiprojekt_extractTitleFromXml_SO "xml path"
    assertEquals "check return value" \
        "$G_RETUNAV" "$?"

    scpmocker_resetFunction xml_extractXmlTag
}

test_napiprojekt_extractTitleFromXml_failsIfNoMovieTagOrEmpty() {
    scpmocker_patchFunction xml_extractXmlTag
    scpmocker -c func_xml_extractXmlTag program -s "success"
    scpmocker -c func_xml_extractXmlTag program -s ""

    napiprojekt_extractTitleFromXml_SO "xml path"
    assertEquals "check return value" \
        "$G_RETUNAV" "$?"

    scpmocker_resetFunction xml_extractXmlTag
}

test_napiprojekt_extractTitleFromXml_extractsTitle() {
    scpmocker_patchFunction xml_extractXmlTag
    scpmocker -c func_xml_extractXmlTag program -s "success"
    scpmocker -c func_xml_extractXmlTag program -s "<movie></movie>"
    scpmocker -c func_xml_extractXmlTag program -s "title"

    local title=
    title=$(napiprojekt_extractTitleFromXml_SO "xml path")

    assertEquals "check return value" \
        "$G_RETOK" "$?"

    assertEquals "check title" \
        "title" "$title"

    scpmocker_resetFunction xml_extractXmlTag
}


test_napiprojekt_downloadSubtitlesLegacy_failsInNonLegacyMode() {
    ___g_napiprojekt_napiprojektId="NapiProjektPython"
    napiprojekt_downloadSubtitlesLegacy "md5 sum" "hash" "output" "PL"
    assertEquals "check return value" \
        "$G_RETFAIL" "$?"
}

test_napiprojekt_downloadSubtitlesLegacy_failsOnHttpFailure() {
    ___g_napiprojekt_napiprojektId="pynapi"

    scpmocker_patchFunction http_downloadUrl_SOSE
    scpmocker -c func_http_downloadUrl_SOSE program -e 1

    napiprojekt_downloadSubtitlesLegacy "md5 sum" "hash" "output" "PL"
    assertEquals "check return value" \
        "$G_RETFAIL" "$?"

    assertEquals "check http_downloadUrl_SOSE call count" \
        1 "$(scpmocker -c func_http_downloadUrl_SOSE status -C)"

    scpmocker_resetFunction http_downloadUrl_SOSE
}

test_napiprojekt_downloadSubtitlesLegacy_worksCorrectInLegacyModes() {
    local lang="PL"
    local videoMd5Sum="123456"
    local h="thisisvideohash"
    local subsPath="$(mktemp -p "$SHUNIT_TMPDIR")"
    local fakeSubsData="this is a line of subs"

    ___g_napiprojektCredentials[0]="username"
    ___g_napiprojektCredentials[1]="somepassword"

    scpmocker_patchFunction http_downloadUrl_SOSE
    scpmocker_patchFunction fs_mktempFile_SO
    scpmocker_patchFunction fs_garbageCollect

    local m=
    local modes=( pynapi other other pynapi )

    # generate some fake subs
    for m in "${!modes[@]}"; do
        scpmocker -c func_http_downloadUrl_SOSE program -e 0

        echo > "$subsPath"
        local i=
        for i in {1..32}; do
            echo "$fakeSubsData $i" >> "$subsPath"
        done

        if [ "other" = "${modes[$m]}" ]; then
            local tmp7zArchive="$(mktemp -p "$SHUNIT_TMPDIR").7z"
            echo "$(<${subsPath})" | \
                7z a -t7z -si -p"${g_napiprojektPassword}" \
                "$tmp7zArchive" >/dev/null

            scpmocker -c func_fs_mktempFile_SO program -e 0 -s "$tmp7zArchive"
        fi

        ___g_napiprojekt_napiprojektId="${modes[$m]}"
        local url="${g_napiprojektBaseUrl}${g_napiprojektApiLegacyUri}"
        url="${url}?l=${lang}&f=${videoMd5Sum}"
        url="${url}&t=${h}&v=${___g_napiprojekt_napiprojektId}"
        url="${url}&kolejka=false&napios=posix"
        url="${url}&nick=${___g_napiprojektCredentials[0]}"
        url="${url}&pass=${___g_napiprojektCredentials[1]}"

        napiprojekt_downloadSubtitlesLegacy \
            "$videoMd5Sum" "$h" "${subsPath}" "$lang"

        assertEquals "check return value mode [${modes[$m]}]" \
            "$G_RETOK" "$?"

        local expectedArgv=
        if [ "other" = "${modes[$m]}" ]; then
            expectedArgv="$url $tmp7zArchive"
        else
            expectedArgv="$url $subsPath"
        fi

        assertEquals "check http_downloadUrl_SOSE argv in mode [${modes[$m]}]" \
            "$expectedArgv" \
            "$(scpmocker -c func_http_downloadUrl_SOSE status -A "$(( m + 1 ))")"
    done

    assertEquals "check http_downloadUrl_SOSE call count" \
        "${#modes[@]}" "$(scpmocker -c func_http_downloadUrl_SOSE status -C)"

    scpmocker_resetFunction http_downloadUrl_SOSE
    scpmocker_resetFunction fs_mktempFile_SO
    scpmocker_resetFunction fs_garbageCollect
}

test_napiprojekt_downloadSubtitlesLegacy_failsIfSubsTooShort() {
    local lang="PL"
    local videoMd5Sum="123456"
    local h="thisisvideohash"
    local subsPath="$(mktemp -p "$SHUNIT_TMPDIR")"
    local fakeSubsData="this is a line of subs"

    ___g_napiprojektCredentials[0]="username"
    ___g_napiprojektCredentials[1]="somepassword"

    scpmocker_patchFunction http_downloadUrl_SOSE
    scpmocker_patchFunction fs_garbageCollect

    scpmocker -c func_http_downloadUrl_SOSE program -e 0

    echo "$fakeSubsData" >> "$subsPath"

    ___g_napiprojekt_napiprojektId="pynapi"
    napiprojekt_downloadSubtitlesLegacy \
        "$videoMd5Sum" "$h" "${subsPath}" "$lang"

    assertEquals "check return value" \
        "$G_RETFAIL" "$?"

    assertEquals "check mock call count" \
        1 "$(scpmocker -c func_fs_garbageCollect status -C)"

    scpmocker_resetFunction http_downloadUrl_SOSE
    scpmocker_resetFunction fs_garbageCollect
}

test_napiprojekt_downloadCoverLegacy_failsOnHttpFailure() {
    local h=123456
    local outputFile=$(mktemp -p "$SHUNIT_TMPDIR")

    scpmocker_patchFunction http_downloadUrl_SOSE
    scpmocker -c func_http_downloadUrl_SOSE program -e 1

    napiprojekt_downloadCoverLegacy "$h" "$outputFile"
    assertEquals "check rv" \
        "$G_RETFAIL" "$?"

    assertEquals "check mock call count" \
        1 "$(scpmocker -c func_http_downloadUrl_SOSE status -C)"

    scpmocker_resetFunction func_http_downloadUrl_SOSE
}

test_napiprojekt_downloadCoverLegacy_failsIfOutputIsEmpty() {
    local h=123456
    local outputFile=$(mktemp -p "$SHUNIT_TMPDIR")

    scpmocker_patchFunction http_downloadUrl_SOSE
    scpmocker_patchFunction fs_garbageCollect

    scpmocker -c func_http_downloadUrl_SOSE program -e 0
    scpmocker -c func_fs_garbageCollect program -e 0

    napiprojekt_downloadCoverLegacy "$h" "$outputFile"
    assertEquals "check rv" \
        "$G_RETUNAV" "$?"

    assertEquals "check http_downloadUrl_SOSE mock call count" \
        1 "$(scpmocker -c func_http_downloadUrl_SOSE status -C)"

    assertEquals "check fs_garbageCollect mock call count" \
        1 "$(scpmocker -c func_fs_garbageCollect status -C)"

    scpmocker_resetFunction fs_garbageCollect
    scpmocker_resetFunction func_http_downloadUrl_SOSE
}

test_napiprojekt_downloadCoverLegacy_worksCorrectInValidScenario() {
    local h=123456
    local outputFile=$(mktemp -p "$SHUNIT_TMPDIR")
    local fakeCoverData="This is some fake cover data"

    scpmocker_patchFunction http_downloadUrl_SOSE
    scpmocker -c func_http_downloadUrl_SOSE program -e 0

    echo "$fakeCoverData" > "$outputFile"

    napiprojekt_downloadCoverLegacy "$h" "$outputFile"
    assertEquals "check rv" \
        "$G_RETOK" "$?"

    local url="${g_napiprojektBaseUrl}${g_napiprojektCoverUri}"
    url="${url}?id=${h}&oceny=-1"

    assertEquals "check http_downloadUrl_SOSE mock call count" \
        1 "$(scpmocker -c func_http_downloadUrl_SOSE status -C)"

    assertEquals "check http_downloadUrl_SOSE call arguments" \
        "$url $outputFile" \
        "$(scpmocker -c func_http_downloadUrl_SOSE status -A 1)"

    scpmocker_resetFunction func_http_downloadUrl_SOSE
}

# shunit call
. shunit2
