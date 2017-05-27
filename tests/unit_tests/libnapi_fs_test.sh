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
. ../../libs/libnapi_assoc.sh


# fakes/mocks
. fake/libnapi_logging_fake.sh
. mock/scpmocker.sh

# module under test
. ../../libs/libnapi_fs.sh

setUp() {
    scpmocker_setUp

    # restore original values
    ___g_fsWrappers=( 'none' 'none' 'none' 'none' 'cp' 'none' 'none' )
    ___g_fsGarbageCollectorLog=
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

test_fs_garbageCollectUnexisting_CollectsTheFileCreatedLater() {
    local tmpFile="${SHUNIT_TMPDIR}/fakeFile"
    local garbageLog="$(mktemp -p "$SHUNIT_TMPDIR")"

    assertFalse "check if exists initially" \
        "[ -e $tmpFile ]"

    ___g_fsGarbageCollectorLog="$garbageLog"
    fs_garbageCollectUnexisting "$tmpFile"

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

test_fs_mktempDir_wrappsMkTempAndGarbageCollects() {
    local fakeTmpDir="/fake/temporary/directory"
    scpmocker_patchCommand "mktemp"

    scpmocker -c mktemp program -s "$fakeTmpDir"

    assertEquals "check command output" \
        "${fakeTmpDir}/" "$(fs_mktempDir_SO)"
}

test_fs_mktempFile_wrappsMkTempAndGarbageCollects() {
    local fakeTmpFile="/fake/temporary/file"
    scpmocker_patchCommand "mktemp"

    scpmocker -c mktemp program -s "$fakeTmpFile"

    assertEquals "check command output" \
        "${fakeTmpFile}" "$(fs_mktempFile_SO)"
}

test_fs_isVideoFile_evaluatesExtensionsAsExpected() {
    local supportedFormats=( 'avi' \
        'rmvb' 'mov' 'mp4' 'mpg' 'mkv' \
        'mpeg' 'wmv' '3gp' 'asf' 'divx' \
        'm4v' 'mpe' 'ogg' 'ogv' 'qt' )

    local unsupportedFormats=( 'txt' \
       'obj' 'mk' 'md' 'sh' 'cpp' 'mp3' 'vqf' 'vorbis' )

    for e in "${supportedFormats[@]}"; do
        local filePath="/some fake/path/some video file name.${e}"
        fs_isVideoFile "$filePath"
        assertTrue "check for supported format [$e]" $?
    done

    for e in "${unsupportedFormats[@]}"; do
        local filePath="/some fake/path/some video file name.${e}"
        fs_isVideoFile "$filePath"
        assertFalse "check for supported format [$e]" $?
    done
}

test_fs_getFps_failsIfNoFpsTool() {
    ___g_fsWrappers[$___g_fsFps]='none'

    fs_getFps_SO

    assertEquals "check for return value" \
        "$G_RETUNAV" "$?"
}

_genericConfigureToolTest() {
    local configFunc="$1"
    local idx="$2"
    local expectedLinux="$3"
    local expectedDarwin="$4"
    local orig="${___g_fsWrappers[$idx]}"

    scpmocker_patchFunction "wrappers_isSystemDarwin"
    scpmocker -c func_wrappers_isSystemDarwin program -e 1
    scpmocker -c func_wrappers_isSystemDarwin program -e 0

    "$configFunc"
    assertEquals "check command on linux" \
        "$expectedLinux" "${___g_fsWrappers[$idx]}"

    # restore original value to run the test again
    ___g_fsWrappers[$idx]="$orig"

    "$configFunc"
    assertEquals "check command on darwin" \
        "$expectedDarwin" "${___g_fsWrappers[$idx]}"

    assertEquals "check for mock call count" \
        2 "$(scpmocker -c func_wrappers_isSystemDarwin status -C)"

    scpmocker_resetFunction "wrappers_isSystemDarwin"
}

test_fs_configureBase64_detection() {
    _genericConfigureToolTest \
        _fs_configureBase64_GV \
        "$___g_fsBase64" \
        "base64 -d" \
        "base64 -D"
}

test_fs_configureMd5_detection() {
    _genericConfigureToolTest \
        _fs_configureMd5_GV \
        "$___g_fsMd5" \
        "md5sum" \
        "md5"
}

test_fs_configureStat_detection() {
    scpmocker_patchCommand "stat"
    scpmocker -c stat program -e 1

    _genericConfigureToolTest \
        _fs_configureStat_GV \
        "$___g_fsStat" \
        "stat -c%s " \
        "stat -f%z "
}

test_fs_configureStat_setStatCmdOnDarwinIfGnuStatInstalledThroughMacports() {
    scpmocker_patchCommand "stat"
    scpmocker -c stat program -e 0

    _genericConfigureToolTest \
        _fs_configureStat_GV \
        "$___g_fsStat" \
        "stat -c%s " \
        "stat -c%s "
}

test_fs_configureUnlink_detection() {
    scpmocker_patchFunction "tools_isDetected"
    scpmocker -c func_tools_isDetected program -e 0

    _fs_configureUnlink_GV

    assertEquals "check the wrappers array" \
        "unlink" "${___g_fsWrappers[$___g_fsUnlink]}"

    assertEquals "check mock call count" \
        1 "$(scpmocker -c func_tools_isDetected status -C)"

    # restore the original
    scpmocker_resetFunction "tools_isDetected"
}

test_fs_configureUnlink_fallbackToRm() {
    scpmocker_patchFunction "tools_isDetected"
    scpmocker -c func_tools_isDetected program -e 1

    _fs_configureUnlink_GV

    assertEquals "check the wrappers array" \
        "rm -rf" "${___g_fsWrappers[$___g_fsUnlink]}"

    assertEquals "check mock call count" \
        1 "$(scpmocker -c func_tools_isDetected status -C)"

    # restore the original
    scpmocker_resetFunction "tools_isDetected"
}

test_fs_configure7z_detection() {
    scpmocker_patchFunction "tools_isDetected"
    scpmocker -c func_tools_isDetected program -e 1
    scpmocker -c func_tools_isDetected program -e 0
    scpmocker -c func_tools_isDetected program -e 0

    _fs_configure7z_GV

    assertEquals "check the wrappers array for 7z" \
        "7z" "${___g_fsWrappers[$___g_fs7z]}"

    ___g_fsWrappers[$___g_fs7z]='none'
    _fs_configure7z_GV
    assertEquals "check the wrappers array for 7za" \
        "7za" "${___g_fsWrappers[$___g_fs7z]}"

    assertEquals "check mock call count" \
        3 "$(scpmocker -c func_tools_isDetected status -C)"

    # restore the original
    scpmocker_resetFunction "tools_isDetected"
}

test_fs_garbageCollectorCleaner_cleansAllAccumulatedEntries() {
    scpmocker_patchCommand "rm"
    local log="$(mktemp -p "${SHUNIT_TMPDIR}")"
    local entries=( 'file1' 'file2' 'file with spaces' 'some other file')
    local nonExisting=( 'nonexisting1' 'other' 'other non existing file' )
    local nEntries="${#entries[@]}"

    for e in "${entries[@]}"; do
        echo "${SHUNIT_TMPDIR}/$e" >> "$log"
        touch "${SHUNIT_TMPDIR}/$e"

        scpmocker -c rm program
    done

    for e in "${nonExisting[@]}"; do
        echo "${SHUNIT_TMPDIR}/$e" >> "$log"
    done

    ___g_fsGarbageCollectorLog="$log"
    _fs_garbageCollectorCleaner

    assertEquals "check rm mock call count" \
        "$(( nEntries + 1 ))" "$(scpmocker -c rm status -C)"

    for i in "${!entries[@]}"; do

        assertEquals "check rm mock call count argv [$i]" \
            "-rf ${SHUNIT_TMPDIR}/${entries[$i]}" \
            "$(scpmocker -c rm status -A "$(( i + 1 ))")"
    done
}

test_fs_configureGarbageCollector_installsExitTraps() {
    scpmocker_patchFunction "trap"
    scpmocker_patchCommand "mktemp"
    scpmocker -c func_trap program
    scpmocker -c mktemp program

    _fs_configureGarbageCollector

    assertEquals "check trap mock call count" \
        "1" "$(scpmocker -c func_trap status -C)"

    assertEquals "check mktemp mock call count" \
        "1" "$(scpmocker -c mktemp status -C)"

    scpmocker_resetFunction "trap"
}

test_fs_verifyFpsTool_exitsIfNoToolAvailable() {
    ___g_fsWrappers[$___g_fsFps]='unavailable'
    _fs_verifyFpsTool

    assertEquals "check return value" \
        $? "$G_RETUNAV"
}

test_fs_verifyFpsTool_picksTheFirstAvailableTool() {
    local tool="some_tool"
    scpmocker_patchFunction "tools_isInGroupAndDetected"
    scpmocker_patchFunction "tools_getFirstAvailableFromGroup_SO"

    scpmocker -c func_tools_isInGroupAndDetected program
    scpmocker -c func_tools_getFirstAvailableFromGroup_SO program -s "$tool"

    _fs_verifyFpsTool

    assertEquals "check return value" \
        $? "$G_RETOK"

    assertEquals "check configured tool" \
        "$tool" "${___g_fsWrappers[$___g_fsFps]}"

    scpmocker_resetFunction "tools_isInGroupAndDetected"
    scpmocker_resetFunction "tools_getFirstAvailableFromGroup_SO"
}

test_fs_getFpsWithTool_mplayer() {
    scpmocker_patchCommand "mplayer"
    scpmocker_patchFunction "tools_isDetected"

    local mplayerOutput=
    local fps=

    read -d "" mplayerOutput << EOF
MPlayer SVN-r37916 (C) 2000-2017 MPlayer Team
225 audio & 460 video codecs
do_connect: could not connect to socket
connect: No such file or directory
Failed to open LIRC support. You will not be able to use your remote control.

Playing Green Wing Season 1 Episode 1-RVa9PB8yezQ.mp4.
libavformat version 57.56.100 (external)
libavformat file format detected.
[mov,mp4,m4a,3gp,3g2,mj2 @ 0x7f1b0b26cf20]Protocol name not provided, cannot determine if input is local or a network protocol, buffers and access patterns cannot be configured optimally without knowing the protocol
ID_VIDEO_ID=0
[lavf] stream 0: video (h264), -vid 0
ID_AUDIO_ID=0
[lavf] stream 1: audio (aac), -aid 0, -alang und
VIDEO:  [H264]  1280x720  24bpp  30.000 fps  1346.8 kbps (164.4 kbyte/s)
==========================================================================
Opening video decoder: [ffmpeg] FFmpeg's libavcodec codec family
libavcodec version 57.64.101 (external)
Selected video codec: [ffh264] vfm: ffmpeg (FFmpeg H.264)
==========================================================================
ID_VIDEO_CODEC=ffh264
Clip info:
 major_brand: isom
ID_CLIP_INFO_NAME0=major_brand
ID_CLIP_INFO_VALUE0=isom
 minor_version: 512
ID_CLIP_INFO_NAME1=minor_version
ID_CLIP_INFO_VALUE1=512
 compatible_brands: isomiso2avc1mp41
ID_CLIP_INFO_NAME2=compatible_brands
ID_CLIP_INFO_VALUE2=isomiso2avc1mp41
 encoder: Lavf57.56.100
ID_CLIP_INFO_NAME3=encoder
ID_CLIP_INFO_VALUE3=Lavf57.56.100
ID_CLIP_INFO_N=4
Load subtitles in ./
ID_FILENAME=Green Wing Season 1 Episode 1-RVa9PB8yezQ.mp4
ID_DEMUXER=lavfpref
ID_VIDEO_FORMAT=H264
ID_VIDEO_BITRATE=1346752
ID_VIDEO_WIDTH=1280
ID_VIDEO_HEIGHT=720
ID_VIDEO_FPS=30.000
ID_VIDEO_ASPECT=0.0000
ID_AUDIO_FORMAT=MP4A
ID_AUDIO_BITRATE=125584
ID_AUDIO_RATE=44100
ID_AUDIO_NCH=2
ID_START_TIME=0.00
ID_LENGTH=3047.43
ID_SEEKABLE=1
ID_CHAPTERS=0
==========================================================================
Opening audio decoder: [ffmpeg] FFmpeg/libavcodec audio decoders
AUDIO: 44100 Hz, 2 ch, floatle, 125.6 kbit/4.45% (ratio: 15698->352800)
ID_AUDIO_BITRATE=125584
ID_AUDIO_RATE=44100
ID_AUDIO_NCH=2
Selected audio codec: [ffaac] afm: ffmpeg (FFmpeg AAC (MPEG-2/MPEG-4 Audio))
==========================================================================
AO: [null] 44100Hz 2ch floatle (4 bytes per sample)
ID_AUDIO_CODEC=ffaac
Starting playback...
EOF

    scpmocker -c mplayer program -s "$mplayerOutput"

    fps=$(_fs_getFpsWithTool "mplayer")

    assertEquals "check mock call count" \
        1 "$(scpmocker -c mplayer status -C)"

    assertEquals "check fps" \
        "30.000" "$fps"

    scpmocker_resetFunction "tools_isDetected"
}

test_fs_getFpsWithTool_mediainfo() {
    scpmocker_patchCommand "mediainfo"
    scpmocker_patchFunction "tools_isDetected"
    scpmocker -c mediainfo program -s "25.000"

    local fps=
    fps=$(_fs_getFpsWithTool "mediainfo")

    assertEquals "check mock call count" \
        1 "$(scpmocker -c mediainfo status -C)"

    assertEquals "check fps" \
        "25.000" "$fps"

    scpmocker_resetFunction "tools_isDetected"
}

test_fs_getFpsWithTool_ffmpeg() {
    scpmocker_patchCommand "ffmpeg"
    scpmocker_patchFunction "tools_isDetected"

    scpmocker -c ffmpeg program -s "Stream #0:0(und): \
Video: h264 (Main) (avc1 / 0x31637661), yuv420p(tv, bt709), \
1280x720 [SAR 1:1 DAR 16:9], 1346 kb/s, \
30 fps, 30 tbr, 90k tbn, 60 tbc (default)"

    local fps=
    fps=$(_fs_getFpsWithTool "ffmpeg")

    assertEquals "check mock call count" \
        1 "$(scpmocker -c ffmpeg status -C)"

    assertEquals "check fps" \
        "30" "$fps"

    scpmocker_resetFunction "tools_isDetected"
}

test_fs_getFpsWithTool_ffprobe() {
    scpmocker_patchCommand "ffprobe"
    scpmocker_patchFunction "tools_isDetected"

    scpmocker -c ffprobe program -s "stream,30/1,30/1"

    local fps=
    fps=$(_fs_getFpsWithTool "ffprobe")

    assertEquals "check mock call count" \
        1 "$(scpmocker -c ffprobe status -C)"

    assertEquals "check fps" \
        "30" "$fps"

    scpmocker_resetFunction "tools_isDetected"
}

test_fs_setFpsTool_performsToolVerification() {
    scpmocker_patchFunction "_fs_verifyFpsTool"
    scpmocker -c func__fs_verifyFpsTool program

    local fakeTool="abc"
    fs_setFpsTool_GV "$fakeTool"

    assertEquals "check the wrappers array" \
        "$fakeTool" "${___g_fsWrappers[$___g_fsFps]}"

    assertEquals "check mock call count" \
        1 "$(scpmocker -c func__fs_verifyFpsTool status -C)"

    # restore the original
    scpmocker_resetFunction "_fs_verifyFpsTool"
}

test_fs_setFpsTool_resetsTheWrappersArrayIfVerificationFails() {
    scpmocker_patchFunction "_fs_verifyFpsTool"
    scpmocker -c func__fs_verifyFpsTool program -e 1

    local fakeTool="abc"
    fs_setFpsTool_GV "$fakeTool"

    assertEquals "check the wrappers array" \
        "unavailable" "${___g_fsWrappers[$___g_fsFps]}"

    assertEquals "check mock call count" \
        1 "$(scpmocker -c func__fs_verifyFpsTool status -C)"

    # restore the original
    scpmocker_resetFunction "_fs_verifyFpsTool"
}

test_fs_getFps_callsFpsToolWrapperWithDetectedTool() {
    local fakeTool="fakeTool"
    ___g_fsWrappers[$___g_fsFps]="$fakeTool"

    scpmocker_patchFunction "_fs_getFpsWithTool"
    scpmocker -c func__fs_getFpsWithTool program

    fs_getFps_SO

    assertEquals "check for mock call count" \
        1 "$(scpmocker -c func__fs_getFpsWithTool status -C)"

    scpmocker_resetFunction "_fs_getFpsWithTool"
}

# shunit call
. shunit2
