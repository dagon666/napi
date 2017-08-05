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

########################################################################

#
# @brief convert charset of the file
# @param input file path
# @param output charset
# @param input charset or null
#
_subs_convertEncoding() {
    local filePath="$1"
    local destEncoding="${2:-utf8}"
    local sourceEncoding="${3:-}"

    # detect charset
    [ -z "$sourceEncoding" ] &&
        sourceEncoding=$(subs_getCharset_SO "$filePath")

    local tmp="$(fs_mktempFile_SO)"
    iconv -f "$sourceEncoding" -t "$destEncoding" \
        "$filePath" > "$tmp" 2>/dev/null && {
        logging_debug $LINENO $"konwersja kodowania pomyslna, zamieniam pliki"
        mv "$tmp" "$filePath"
    }
}

########################################################################

#
# @brief get extension for given subtitle format
#
subs_getSubFormatExtension_SO() {
    declare -a fmte=( 'subrip=srt' 'subviewer2=sub' )
    assoc_lookupValue_SO "$1" "${fmte[@]}" || subs_getDefaultExtension_SO
}

#
# @brief echoes default subtitles extensions
#
subs_getDefaultExtension_SO() {
    sysconf_getKey_SO napiprojekt.subtitles.extension
}

#
# @brief detects the charset of the subtitles file
# @param full path to the subtitles file
#
subs_getCharset_SO() {
    local file="$1"
    local charset=
    local et=

    tools_isDetected "file" || return $G_RETFAIL

    et=$(file \
        --brief \
        --mime-encoding \
        --exclude apptype \
        --exclude tokens \
        --exclude cdf \
        --exclude compress \
        --exclude elf \
        --exclude soft \
        --exclude tar \
        "$file" | wrappers_lcase_SO) || {
        return $G_RETFAIL
    }

    case "$et" in
        *utf*) charset="UTF8";;
        *iso*) charset="ISO-8859-2";;
        us-ascii) charset="US-ASCII";;
        csascii) charset="CSASCII";;
        *ascii*) charset="ASCII";;
        *) charset="WINDOWS-1250";;
    esac

    echo "$charset"
}

#
# @brief convert charset of the file
# @param input file path
# @param encoding
#
subs_convertEncoding() {
    local filePath="$1"
    local encoding="${2:-}"
    local fileName=$(basename "$filePath")

    logging_msg "[$fileName]" $"konwertowanie kodowania do" "$encoding"
    _subs_convertEncoding "$filePath" "$encoding"
}

#
# @brief convert format
# @param full path to the media file
# @param full path of the media file (without filename)
# @param original (as downloaded) subtitles filename
# @param filename to which unconverted subtitles should be renamed
# @param filename for converted subtitles
# @param requested subtitles format
#
subs_convertFormat() {
    local videoFilePath="$1"
    local videoFileDir="$2"
    local sourceSubsFileName="$3"
    local originalFileName="$4"
    local destSubsFileName="$5"
    local format="$6"

    local isDeleteOrigSet="$(sysconf_getKey_SO \
        napiprojekt.subtitles.orig.delete)"

    # verify original file existence before proceeding further
    # shellcheck disable=SC2086
    [ -e "${videoFileDir}/${sourceSubsFileName}" ] || {
        logging_error $"oryginalny plik nie istnieje"
        return $G_RETFAIL
    }

    # for the backup
    local tmp="$(fs_mktempFile_SO)"

    # create backup
    logging_debug $LINENO $"backupuje oryginalny plik jako" "$tmp"
    cp "${videoFileDir}/${sourceSubsFileName}" "$tmp"

    if [ "$isDeleteOrigSet" -eq 1 ]; then
        fs_garbageCollect "${videoFileDir}/${originalFileName}"
    else
        logging_info $LINENO $"kopiuje oryginalny plik jako" \
            "[$originalFileName]"

        [ "${sourceSubsFileName}" != "${originalFileName}" ] &&
            cp "${videoFileDir}/${sourceSubsFileName}" \
                "${videoFileDir}/${originalFileName}"
    fi

    # detect video file framerate
    local fps=

    fps=$(fs_getFps_SO "$videoFilePath")
    if [ -n "$fps" ] && [ "$fps" != "0" ]; then
        logging_msg $"wykryty fps" "$fps"
    else
        logging_msg $"fps nieznany, okr. na podstawie napisow albo wart. domyslna"
        fps=0
    fi

    # attempt conversion
    local convStatus=
    logging_msg $"wolam subotage"
    subotage_processFile \
        "${videoFileDir}/${sourceSubsFileName}" \
        "none" \
        "0" \
        "" \
        "${videoFileDir}/${destSubsFileName}" \
        "${format}" \
        "${fps}" \
        ""
    convStatus=$?

    if [ "$convStatus" -eq "$G_RETOK" ]; then
        # remove the old format if conversion was successful
        logging_msg $"pomyslnie przekonwertowano do" "$format"

        [ "$sourceSubsFileName" != "$destSubsFileName" ] && {
            logging_info $LINENO "usuwam oryginalny plik"
            fs_garbageCollect "${videoFileDir}/${sourceSubsFileName}"
        }

    elif [ "$convStatus" -eq $G_RETNOACT ]; then
        logging_msg $"subotage - konwersja nie jest konieczna"

        # copy the backup to converted
        cp "$tmp" "${videoFileDir}/${destSubsFileName}"

        # get rid of the original file
        [ "$sourceSubsFileName" != "$destSubsFileName" ] &&
            logging_msg "usuwam oryginalny plik" &&
            fs_unlink "${videoFileDir}/${sourceSubsFileName}"

    else
        logging_msg $"konwersja do" "$format" $"niepomyslna"
        # restore the backup (the original file may be corrupted due to failed conversion)
        cp "$tmp" "$videoFileDir/$sourceSubsFileName"
        return $G_RETFAIL
    fi

    return $G_RETOK
}

# EOF
