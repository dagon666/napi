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

___g_subs_defaultExtension='txt'

#
# supported subtitle file formats
#
declare -ar ___g_subs_formats=( "microdvd" "mpl2" "subrip" \
    "subviewer2" "tmplayer" )

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
    iconv -f "$sourceEncoding" -t "$destEncoding" "$filePath" > "$tmp" && {
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

    # this function can cope with that kind of input
    # shellcheck disable=SC2068
    assoc_lookupValue_SO "$1" "${fmte[@]}" ||
        echo "$___g_subs_defaultExtension"
}

#
# @brief echoes default subtitles extensions
#
subs_getDefaultExtension_SO() {
    echo "$___g_subs_defaultExtension"
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
    local fileName=$(basename "$filepath")

    logging_msg "[$filename]" $"konwertowanie kodowania do" "$encoding"
    _subs_convertEncoding "$filePath" "$encoding"
}

#
# @brief checks if the provided format is valid & supported
#
subs_verifySubsFormat() {
    local format="$1"
    logging_debug $LINENO $"weryfikuje format napisow:" "$format"

    # this function can cope with that kind of input
    # shellcheck disable=SC2068
    lookup_key "$format" ${___g_subs_formats[@]} > /dev/null ||
        return $G_RETPARAM
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
    # TODO this function needs to be re-written
    # subotage functionality should be placed in a library
    # and a thin executable should be created for subotage.
    # This function should use the subotage library only and not call to
    # external process.
    local videoFilePath="$1"
    local videoFileDir="$2"
    local sourceSubsFile="$3"
    local originalFileName="$4"
    local destSubsFileName="$5"
    local format="$6"

    local isDeleteOrigSet="$(sysconf_getKey_SO \
        napiprojekt.subtitles.orig.delete)"

    local fps=0
    local subotageFpsOpt=

    # verify original file existence before proceeding further
    # shellcheck disable=SC2086
    [ -e "${videoFileDir}/${sourceSubsFile}" ] || {
        logging_error $"oryginalny plik nie istnieje"
        return $G_RETFAIL
    }

    # for the backup
    local tmp="$(fs_mktempFile_SO)"

    # create backup
    logging_debug $LINENO $"backupuje oryginalny plik jako" "$tmp"
    cp "${videoFileDir}/${sourceSubsFile}" "$tmp"

    if [ "$isDeleteOrigSet" -eq 1 ]; then
        fs_garbageCollect_GV "${videoFileDir}/${originalFileName}"
    else
        logging_info $LINENO $"kopiuje oryginalny plik jako" \
            "[$originalFileName]"
        cp "${videoFileDir}/${sourceSubsFile}" \
            "${videoFileDir}/${originalFileName}"
    fi

    # detect video file framerate
    fps=$(fs_getFps "$videoFilePath")

    if [ -n "$fps" ] && [ "$fps" != "0" ]; then
        logging_msg $"wykryty fps" "$fps"
        subotageFpsOpt="-fi $fps"
    else
        logging_msg $"fps nieznany, okr. na podstawie napisow albo wart. domyslna"
    fi

    logging_msg $"wolam subotage.sh"

    # create ipc file to update the message counter
    local ipcFile="$(fs_mktempFile_SO)"
    local msgCounter=0

    # fps_opt must be expanded for the subotage call
    # shellcheck disable=SC2086
    if subotage.sh \
        -v "$(output_get_verbosity)" \
        -i "${videoFileDir}/${sourceSubsFile}" \
        -of "${format}" \
        -t "$(output_get_fork_id)" \
        -m "$(output_get_msg_counter)" \
        --ipc-file "$ipcFile" \
        -o "$videoFileDir/${destSubsFileName}" \
        $subotageFpsOpt; then

        # update the message counter
        [ -s "$ipcFile" ] &&
            read msgCounter < "$ipcFile" &&
            logging_setMsgCounter "$msgCounter"

        # remove the old format if conversion was successful
        logging_msg $"pomyslnie przekonwertowano do" "$format"

        [ "$sourceSubsFile" != "$destSubsFileName" ] && {
            logging_info $LINENO "usuwam oryginalny plik"
            fs_garbageCollect_GV "${videoFileDir}/${sourceSubsFile}"
        }

    elif [ $? -eq $G_RETNOACT ]; then
        logging_msg $"subotage.sh - konwersja nie jest konieczna"

        #copy the backup to converted
        cp "$tmp" "$path/$conv"

        # get rid of the original file
        [ "$input" != "$conv" ] &&
            _msg "usuwam oryginalny plik" &&
            io_unlink "$path/$input"

    else
        logging_msg $"konwersja do" "$format" $"niepomyslna"
        # restore the backup (the original file may be corrupted due to failed conversion)
        cp "$tmp" "$videoFileDir/$sourceSubsFile"
        return $G_RETFAIL

    fi
}

# EOF

