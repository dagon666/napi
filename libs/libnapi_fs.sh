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

declare -r ___g_fsUnlink=0
declare -r ___g_fsStat=1
declare -r ___g_fsBase64=2
declare -r ___g_fsMd5=3
declare -r ___g_fsCp=4
declare -r ___g_fs7z=5
declare -r ___g_fsFps=6

declare -a ___g_fsWrappers=( 'none' 'none' 'none' \
    'none' 'cp' 'none' 'none' )

___g_fsGarbageCollectorLog=

########################################################################

#
# @brief configure the stat tool
#
_fs_configureStat_GV() {
    [ "${___g_fsWrappers[$___g_fsStat]}" = 'none' ] || return $G_RETNOACT
    # verify stat tool
    ___g_fsWrappers[$___g_fsStat]="stat -c%s "

    if wrappers_isSystemDarwin; then
        # stat may be installed through macports, check if
        # there's a need to reconfigure it to BSD flavour
        ${___g_fsWrappers[$___g_fsStat]} "$0" >/dev/null 2>&1 ||
            ___g_fsWrappers[$___g_fsStat]="stat -f%z "
    fi
}

#
# configure the base64 tool
#
_fs_configureBase64_GV() {
    [ "${___g_fsWrappers[$___g_fsBase64]}" = 'none' ] || return $G_RETNOACT
    ___g_fsWrappers[$___g_fsBase64]="base64 -d"

    # verify base64
    wrappers_isSystemDarwin &&
        ___g_fsWrappers[$___g_fsBase64]="base64 -D"
}

#
# configure the md5 tool
#
_fs_configureMd5_GV() {
    [ "${___g_fsWrappers[$___g_fsMd5]}" = 'none' ] || return $G_RETNOACT

    # verify md5 tool
    ___g_fsWrappers[$___g_fsMd5]="md5sum"
    wrappers_isSystemDarwin &&
        ___g_fsWrappers[$___g_fsMd5]="md5"
}

#
# @brief configure the unlink tool
#
_fs_configureUnlink_GV() {
    [ "${___g_fsWrappers[$___g_fsUnlink]}" = 'none' ] || return $G_RETNOACT

    ___g_fsWrappers[$___g_fsUnlink]='rm -rf'
    tools_isDetected "unlink" &&
        ___g_fsWrappers[$___g_fsUnlink]='unlink'
}

#
# @brief verify presence of any of the 7z tools
#
_fs_configure7z_GV() {
    [ "${___g_fsWrappers[$___g_fs7z]}" = 'none' ] || return $G_RETNOACT
    local k=''

    # use 7z or 7za only, 7zr doesn't support passwords
    declare -a t7zs=( '7za' '7z' )

    for k in "${t7zs[@]}"; do
        tools_isDetected "$k" &&
            ___g_fsWrappers[$___g_fs7z]="$k" &&
            break
    done
}

#
# @brief exit callback performing temporary files garbage collection
#
_fs_garbageCollectorCleaner() {
    [ -z "$___g_fsGarbageCollectorLog" ] && return

    logging_debug $LINENO $"usuwam pliki tymczasowe"

    local entry=
    while IFS='' read -r entry && [ -n "$entry"  ]; do
        [ -e "$entry" ] && {
            logging_debug $LINENO $"usuwam" "[$entry]"
            rm -rf "$entry"
        }
    done < "$___g_fsGarbageCollectorLog"

    logging_debug $LINENO \
        $"usuwam dziennik plikow tymczasowych" "[$___g_fsGarbageCollectorLog]"
    rm -rf "$___g_fsGarbageCollectorLog"
}

#
# @brief garbage collector callback installer
#
_fs_configureGarbageCollector() {
    [ -n "$___g_fsGarbageCollectorLog" ] && return
    ___g_fsGarbageCollectorLog=$(mktemp napi.gclog.XXXXXXXX)
    trap _fs_garbageCollectorCleaner EXIT
}

#
# @brief verify configured fps tool
#
_fs_verifyFpsTool() {
    # don't do anything if the tool has been already marked as unavailable
    [ "${___g_fsWrappers[$___g_fsFps]}" = 'unavailable' ] &&
        return $G_RETUNAV

    # verify selected fps tool
    if [ "${___g_fsWrappers[$___g_fsFps]}" = 'none' ] ||
        ! tools_isInGroupAndDetected 'fps' \
        "${___g_fsWrappers[$___g_fsFps]}"; then
        # choose first available as the default tool
        local firstav=''
        firstav=$(tools_getFirstAvailableFromGroup_SO "fps")
        [ -z "$firstav" ] && return $G_RETPARAM
        ___g_fsWrappers[$___g_fsFps]="$firstav"
    fi
}

#
# @brief detect fps of the video file
# @param tool
# @param filepath
#
_fs_getFpsWithTool() {
    local fps=0
    local tbr=0
    local t="${1:-none}"

    local tmp=''
    declare -a atmp=()

    # don't bother if there's no tool available or not specified
    if [ -z "$t" ] ||
        [ "$t" = "none" ] ||
        [ "$t" = "unavailable" ] ||
        ! tools_isDetected; then
        echo $fps
        # shellcheck disable=SC2086
        return $G_RETPARAM
    fi

    case "$t" in
        'mplayer' | 'mplayer2' )
        fps=$($t -identify -vo null \
            -ao null \
            -frames 0 "$2" 2> /dev/null | \
            grep ID_VIDEO_FPS | \
            cut -d '=' -f 2)
        ;;

        'mediainfo' )
        fps=$($t --Output='Video;%FrameRate%' "$2")
        ;;

        'ffmpeg' )
        tmp=$($t -i "$2" 2>&1 | grep "Video:")
        tbr=$(echo "$tmp" | \
            sed 's/, /\n/g' | \
            tr -d ')(' | \
            grep tbr | \
            cut -d ' ' -f 1)
        fps=$(echo "$tmp" | \
            sed 's/, /\n/g' | \
            grep fps | \
            cut -d ' ' -f 1)
        [ -z "$fps" ] && fps="$tbr"
        ;;

        'ffprobe' )
        tmp=$("$t" -v 0 \
            -select_streams v \
            -print_format csv \
            -show_entries \
            stream=avg_frame_rate,r_frame_rate -- "$2" | \
            tr ',' ' ')
        atmp=( $tmp )

        local i=0
        for i in 1 2; do
            local a=$(echo "${atmp[$i]}" | cut -d '/' -f 1)
            local b=$(echo "${atmp[$i]}" | cut -d '/' -f 2)
            [ "${atmp[$i]}" != "0/0" ] && fps=$(wrappers_floatDiv "$a" "$b")
        done
        ;;

        *)
        ;;
    esac

    # just a precaution
    echo "$fps" | cut -d ' ' -f 1
}

########################################################################

#
# @brief configure the library
#
fs_configure_GV() {
    _fs_configureStat_GV
    _fs_configureBase64_GV
    _fs_configureMd5_GV
    _fs_configureUnlink_GV
    _fs_configure7z_GV
    _fs_configureGarbageCollector
    _fs_verifyFpsTool
}

#
# @brief stat wrapper
#
fs_stat_SO() {
    ${___g_fsWrappers[$___g_fsStat]} "$@"
}

#
# @brief base64 wrapper
#
fs_base64Decode_SO() {
    ${___g_fsWrappers[$___g_fsBase64]} "$@"
}

#
# @brief md5 wrapper
#
fs_md5_SO() {
    ${___g_fsWrappers[$___g_fsMd5]} "$@"
}

#
# @brief wrapper for copy function
#
fs_cp() {
    ${___g_fsWrappers[$___g_fsCp]} "$@"
}

#
# @brief set copy executable
#
fs_setCp_GV() {
    ___g_fsWrappers[$___g_fsCp]="${1:-cp}"
}

#
# @brief unlink wrapper
#
fs_unlink() {
    ${___g_fsWrappers[$___g_fsUnlink]} "$@"
}

#
# @brief 7z wrapper
#
fs_7z_SO() {
    [ "${___g_fsWrappers[$___g_fs7z]}" != 'none' ] &&
        ${___g_fsWrappers[$___g_fs7z]} "$@"
}

#
# @brief returns true if 7z is available
#
fs_is7zAvailable() {
    [ "${___g_fsWrappers[$___g_fs7z]}" != 'none' ]
}

#
# @brief adds a given file to be garbage collected at exit
#
fs_garbageCollect() {
    [ -e "$1" ] && echo "$1" >> "$___g_fsGarbageCollectorLog"
}

#
# @brief create temporary directory
#
fs_mktempDir_SO() {
    local dirPath=$(mktemp -d -t napi.XXXXXXXX)
    fs_garbageCollect "${dirPath}/"
    echo "${dirPath}/"
}

#
# @brief create temporary file
#
fs_mktempFile_SO() {
    local filePath=$(mktemp -t napi.XXXXXXXX)
    fs_garbageCollect "${filePath}"
    echo "${filePath}"
}

#
# @brief: check if the given file is a supported video file
# @param: video filename
#
fs_isVideoFile() {
    local filename=$(basename "$1")
    local extension=$(wrappers_getExt_SO "$filename" | wrappers_lcase_SO)
    local formats=( 'avi' 'rmvb' 'mov' 'mp4' 'mpg' 'mkv' \
        'mpeg' 'wmv' '3gp' 'asf' 'divx' \
        'm4v' 'mpe' 'ogg' 'ogv' 'qt' )

    assoc_lookupKey_SO "$extension" "${formats[@]}" >/dev/null
}

#
# @brief set fps tool
#
fs_setFpsTool_GV() {
    ___g_fsWrappers[$___g_fsFps]="${1:-none}"

    _fs_verifyFpsTool ||
        ___g_fsWrappers[$___g_fsFps]="unavailable"
}

#
# @brief get fps of a media file
#
fs_getFps_SO() {
    [ "${___g_fsWrappers[$___g_fsFps]}" = 'none' ] &&
        return "$G_RETUNAV"
    _fs_getFpsWithTool "${___g_fsWrappers[$___g_fsFps]}" "$@"
}

# EOF
