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

# globals

# @brief napiprojekt.pl user credentials
# 0 - username
# 1 - password
declare -a ___g_napiprojektCredentials=( '' '' )

# - pynapi - identifies itself as pynapi
# - other - identifies itself as other
# - NapiProjektPython - uses new napiprojekt3 API - NapiProjektPython
# - NapiProjekt - uses new napiprojekt3 API - NapiProjekt
___g_napiprojekt_napiprojektId='NapiProjektPython'

########################################################################

#
# @brief check if 7z is needed
#
# 7z is required when using specific API type.
#
_napiprojekt_is7zRequired() {
    [ "$___g_napiprojekt_napiprojektId" = 'other' ] ||
        [ "$___g_napiprojekt_napiprojektId" = 'NapiProjektPython' ] ||
        [ "$___g_napiprojekt_napiprojektId" = 'NapiProjekt' ]
}

#
# @brief verify if the configured napi id is correct and auto-correct it if
# it's not.
#
_napiprojekt_verifyNapiprojektId() {
    case "$___g_napiprojekt_napiprojektId" in
        'pynapi' | 'other' | 'NapiProjektPython' | 'NapiProjekt' )
            ;;

        *) # any other - revert to napi projekt 'classic'
            logging_warning "Nieznany napiprojekt API id"
            # shellcheck disable=SC2086
            return $G_RETPARAM
            ;;
    esac
}

_napiprojekt_verifyNapiprojektCredentials() {
    if [ -z "${___g_napiprojektCredentials[0]}" ] &&
        [ -n "${___g_napiprojektCredentials[1]}" ]; then
        logging_warning $"podano haslo, brak loginu. tryb anonimowy"
        return $G_RETPARAM
    fi

    if [ -z "${___g_napiprojektCredentials[1]}" ] &&
        [ -n "${___g_napiprojektCredentials[0]}" ]; then
        logging_warning $"podano login, brak hasla. tryb anonimowy"
        return $G_RETPARAM
    fi
}

########################################################################

#
# @brief set the id used to identify with napiprojekt servers
#
napiprojekt_verifyArguments_GV() {
    # 7z check
    if _napiprojekt_is7zRequired && ! fs_is7zAvailable; then
        logging_error $"Tryb legacy: 7z nie jest dostepny. id = 'pynapi'"
        ___g_napiprojekt_napiprojektId='pynapi'
    fi

    _napiprojekt_verifyNapiprojektCredentials ||
        ___g_napiprojektCredentials=( '' '' )
}

#
# @brief configures napiprojekt id value
#
napiprojekt_setNapiprojektId_GV() {
    ___g_napiprojekt_napiprojektId="${1:-pynapi}"
    _napiprojekt_verifyNapiprojektId || ___g_napiprojekt_napiprojektId='pynapi'
}

#
# @brief true if configured napiprojekt id is legacy id
#
napiprojekt_isNapiprojektIdLegacy() {
    [ "$___g_napiprojekt_napiprojektId" = "pynapi" ] ||
        [ "$___g_napiprojekt_napiprojektId" = "other" ]
}

#
# @brief configures napiprojekt username
#
napiprojekt_setNapiprojektUserName_GV() {
    ___g_napiprojektCredentials[0]="${1:-}"
}

#
# @brief configures napiprojekt password
#
napiprojekt_setNapiprojektPassword_GV() {
    ___g_napiprojektCredentials[1]="${1:-}"
}

#
# @brief: mysterious f() function
# @param: md5sum
#
napiprojekt_f_SO() {
    declare -a t_idx=( 0xe 0x3 0x6 0x8 0x2 )
    declare -a t_mul=( 2 2 5 4 3 )
    declare -a t_add=( 0 0xd 0x10 0xb 0x5 )
    local sum="$1"
    local b=""
    local i=0

    # for i in {0..4}; do
    # again in order to be compliant with bash < 3.0
    for i in $(seq 0 4); do
        local a="${t_add[$i]}"
        local m="${t_mul[$i]}"
        local g="${t_idx[$i]}"

        local t=$(( a + 16#${sum:$g:1} ))
        local v=$(( 16#${sum:$t:2} ))

        local x=$(( (v*m) % 0x10 ))
        local z=$(printf "%x" "$x")
        b="${b}${z}"
    done
    echo "$b"
}

#
# @brief calculate md5 hash from video file
#
napiprojekt_calculateMd5VideoFile_SO() {
    local file="${1:-}"
    [ -e "$file" ] || return $G_RETFAIL
    dd if="$file" bs=1024k count=10 2> /dev/null | \
        fs_md5_SO | \
        cut -d ' ' -f 1
}

#
# @brief strip any mime prefixes from the hash
#
napiprojekt_normalizeHash_SO() {
    echo "${1##napiprojekt:}" | wrappers_lcase_SO
}

#
# @brief download xml data using new napiprojekt API
# @param md5sum of the media file
# @param file name of the media file
# @param size of the media file in bytes
# @param path of the xml file (including filename)
# @param language (PL if not provided)
#
# If file name is an empty string and file size is zero, a direct query will be
# done in mode 17 (whatever it means)
#
napiprojekt_downloadXml() {
    # input data
    local md5sum=${1:-0}
    local movieFile="${2:-}"
    local byteSize=${3:-0};
    local outputFile="${4:-}"
    local lang="${5:-PL}"

    # interaction mode
    local mode=31

    # mode 17 means we will perform a direct download and ask for subs hash
    # directly, without inspecting the file at all.
    [ -z "$movieFile" ] && [ "$byteSize" = "0" ] && mode=17

    local data="mode=$mode&\
client=${___g_napiprojekt_napiprojektId}&\
client_ver=${g_napiprojektClientVersion}&\
user_nick=${___g_napiprojektCredentials[0]}&\
user_password=${___g_napiprojektCredentials[1]}&\
downloaded_subtitles_id=$md5sum&\
downloaded_subtitles_lang=$lang&"

    # in mode 31 we deliver the file details as well
    [ "$mode" = "31" ] && data="${data}\
downloaded_cover_id=$md5sum&\
advert_type=flashAllowed&\
video_info_hash=$md5sum&\
nazwa_pliku=$movieFile&\
rozmiar_pliku_bajty=$byteSize&"

    # append the end query marker
    data="${data}the=end"

    local httpCodes=
    httpCodes=$(http_downloadUrl_SOSE \
        "${g_napiprojektBaseUrl}${g_napiprojektApi3Uri}" \
        "$outputFile" "$data" 2>&1)
    local status=$?

    logging_info $LINENO $"otrzymane odpowiedzi http:" "[$httpCodes]"

    # shellcheck disable=SC2086
    if [ "$status" -ne $G_RETOK ]; then
        logging_error $"blad wgeta. nie mozna pobrac pliku" "[$outputFile]"
        # ... and exit
        return $G_RETFAIL
    fi
}

#
# @brief verifies napiprojekt's XML response
#
napiprojekt_verifyXml() {
    local xmlPath="${1:-}"
    local minSize=32
    [ -e "${xmlPath}" ] && [ "$(fs_stat_SO "$xmlPath")" -gt "$minSize" ]
}

#
# @brief extract subtitles out of xml
# @param xml file path
# @param subs file path
#
napiprojekt_extractSubsFromXml() {
    local xmlPath="${1:-}"
    local subsPath="${2:-}"
    local xmlStatus=0
    local rv=$G_RETOK

    # I've got the xml, extract Interesting parts
    xmlStatus=$(xml_extractXmlTag 'status' "$xmlPath" | \
        grep 'success' | wrappers_countLines_SO)

    logging_debug $LINENO $"subs xml status " "[$xmlStatus]"
    if [ "$xmlStatus" -eq 0 ]; then
        logging_warning $"napiprojekt zglasza niepowodzenie - napisy niedostepne"
        # shellcheck disable=SC2086
        return $G_RETUNAV
    fi

    # extract the subs data
    local xmlSubs=$(xml_extractXmlTag 'subtitles' "$xmlPath")

	# check if the subtitles tag exist in the output
	# it's possible that the downloaded XML contains only
	# the cover and metadata
	if [ -z "${xmlSubs}" ]; then
		logging_debug $LINENO $"plik xml nie zawiera taga subtitles"
		logging_info $LINENO $"napisy niedostepne"
        # shellcheck disable=SC2086
        return $G_RETUNAV
	fi

    # extract content
    local subsContent=$(echo "$xmlSubs" | xml_extractXmlTag 'content')

    # create archive file
    local tmp7zArchive=$(fs_mktempFile_SO)
    echo "$subsContent" | \
        xml_extractCdataTag | \
        fs_base64Decode_SO > "$tmp7zArchive"

    if [ -s "$tmp7zArchive" ]; then
        logging_debug $LINENO $"rozpakowuje archiwum ..."
        fs_7z_SO x \
            -y -so \
            -p"$g_napiprojektPassword" \
            "$tmp7zArchive" 2>/dev/null > "$subsPath" || {

            logging_error $"7z zwraca blad. nie mozna rozpakowac napisow"
            rv=$G_RETFAIL
        }
    fi

    # check for size
    [ -s "$subsPath" ] || {
        logging_info $LINENO $"plik docelowy ma zerowy rozmiar"
        rv=$G_RETFAIL
    }

    # get rid of the subs
    [ "$rv" != $G_RETOK ] && fs_garbageCollect "$subsPath"

    # shellcheck disable=SC2086
    return $rv
}

#
# @brief extract cover out of xml
# @param xml file path
# @param cover file path
#
napiprojekt_extractCoverFromXml() {
    local xmlPath="${1:-}"
    local coverPath="${2:-}"
    local xmlStatus=0
    local rv=$G_RETOK

    # I've got the xml, extract Interesting parts
    xmlStatus=$(xml_extractXmlTag 'status' "$xmlPath" | \
        grep 'success' | wrappers_countLines_SO)

    logging_debug $LINENO $"cover xml status" "[$xmlStatus]"
    if [ "$xmlStatus" -eq 0 ]; then
        logging_error $"napiprojekt zglasza niepowodzenie - okladka niedostepna"

        # shellcheck disable=SC2086
        return $G_RETUNAV
    fi

    # extract the cover data
    local xmlCover=$(xml_extractXmlTag 'cover' "$xmlPath")

	if [ -z "$xmlCover" ]; then
		logging_debug $LINENO $"plik xml nie zawiera taga cover"
		logging_info $LINENO $"okladka niedostepne"
        # shellcheck disable=SC2086
        return $G_RETUNAV
	fi

    # write archive data
    echo "$xmlCover" | \
        xml_extractCdataTag | \
        fs_base64Decode_SO > "$coverPath" 2>/dev/null

    [ -s "$coverPath" ] || {
        logging_info $LINENO $"okladka ma zerowy rozmiar, zostanie usunieta"
        fs_garbageCollect "$coverPath"
        rv=$G_RETFAIL
    }

    # shellcheck disable=SC2086
    return $rv
}

#
# @brief extract informations out of xml
# @param xml file path
# @param nfo file path
#
napiprojekt_extractNfoFromXml() {
    local xmlPath="${1:-}"
    local nfoPath="${2:-}"
    local xmlStatus=0
    local rv=$G_RETOK

    local k=
    local v=

    declare -a subsTags=( 'author' 'uploader' 'upload_date' )
    declare -a movieTags=( 'title' 'other_titles' 'year' \
       'country' 'genre' 'direction' \
       'screenplay' 'music' 'imdb_com' \
       'filmweb_pl' 'fdb_pl' 'stopklatka_pl' )

    # I've got the xml, extract Interesting parts
    xmlStatus=$(xml_extractXmlTag 'status' "$xmlPath" \
        | grep 'success' | wrappers_countLines_SO)

    logging_debug $LINENO $"xml status " "[$xmlStatus]"
    if [ "$xmlStatus" -eq 0 ]; then
        logging_error $"napiprojekt zglasza niepowodzenie - informacje niedostepne"
        # shellcheck disable=SC2086
        return $G_RETUNAV
    fi

    # extract the subs data
    local xmlSubs=$(xml_extractXmlTag 'subtitles' "$xmlPath")

    # extract the movie data
    local xmlMovie=$(xml_extractXmlTag 'movie' "$xmlPath")

    # purge the file initially
    echo "nfo generated by napi $g_revision" > "$nfoPath"

    # extract data from subtitles tag
    [ -n "$xmlSubs" ] && for k in "${subsTags[@]}"; do
        v=$(echo "$xmlSubs" | \
            xml_extractXmlTag "$k" | xml_stripXmlTag) &&
            echo "$k: $v" >> "$nfoPath"
    done

    local cdata=0
    local en=
    local pl=

    # extract data from movie tag
    [ -n "$xmlMovie" ] && for k in "${movieTags[@]}"; do
        v=$(echo "$xmlMovie" | xml_extractXmlTag "$k")

        cdata=$(echo "$v" | grep 'CDATA' | wrappers_countLines_SO)
        en=$(echo "$v" | xml_extractXmlTag "en" | xml_stripXmlTag)
        pl=$(echo "$v" | xml_extractXmlTag "pl" | xml_stripXmlTag)

        if [ "$cdata" != "0" ]; then
            v=$(echo "$v" | xml_extractCdataTag | tr -d "\r\n")
        elif [ -n "$en" ] || [ -n "$pl" ]; then
            v="$pl/$en"
        else
            v=$(echo "$v" | xml_stripXmlTag)
        fi

        echo "$k: $v" >> "$nfoPath"
    done

    # shellcheck disable=SC2086
    return $rv
}

#
# @brief extracts movie title from napiprojekt's XML response
#
napiprojekt_extractTitleFromXml_SO() {
    local xmlPath="${1:-}"
    local xmlStatus=0

    # I've got the xml, extract Interesting parts
    xmlStatus=$(xml_extractXmlTag 'status' "$xmlPath" \
        | grep 'success' | wrappers_countLines_SO)

    if [ "$xmlStatus" -eq 0 ]; then
        # shellcheck disable=SC2086
        return $G_RETUNAV
    fi

    # extract the movie data
    local xmlMovie=$(xml_extractXmlTag 'movie' "$xmlPath")

    [ -z "$xmlMovie" ] && {
        logging_debug $LINENO $"brak taga movie"
        return $G_RETUNAV
    }

    echo "$xmlMovie" | xml_extractXmlTag "title"
}

########################################################################

# legacy API

#
# @brief downloads subtitles
#
# @param md5 sum of the video file
# @param hash of the video file
# @param output filepath
# @param requested subtitles language
#
napiprojekt_downloadSubtitlesLegacy() {
    local videoMd5sum="${1:-0}"
    local videoHash="${2:-0}"
    local outputFile="$3"
    local lang="${4:-PL}"

    local downloadFileName="${outputFile}"
    local status=$G_RETFAIL

    napiprojekt_isNapiprojektIdLegacy || {
        logging_error $"To API dziala jedynie w trybie legacy"
        logging_error $"Ustaw NapiId na pynapi lub other"
        return $G_RETFAIL
    }

    # url construction
    local url="${g_napiprojektBaseUrl}${g_napiprojektApiLegacyUri}"
    url="${url}?l=${lang}&f=${videoMd5sum}"
    url="${url}&t=${videoHash}&v=${___g_napiprojekt_napiprojektId}"
    url="${url}&kolejka=false&napios=posix"
    url="${url}&nick=${___g_napiprojektCredentials[0]}"
    url="${url}&pass=${___g_napiprojektCredentials[1]}"

    # log the url with all the variables
    logging_debug $LINENO $"URL" "[$url]"

    [ "other" = "${___g_napiprojekt_napiprojektId}" ] &&
        downloadFileName="$(fs_mktempFile_SO)"

    local httpCodes=
    httpCodes=$(http_downloadUrl_SOSE "$url" \
        "$downloadFileName" 2>&1)
    status=$?

    logging_info $LINENO $"otrzymane odpowiedzi http:" "[$httpCodes]"
    # shellcheck disable=SC2086
    if [ "$status" -ne $G_RETOK ]; then
        logging_error $"blad wgeta. nie mozna pobrac pliku" "[$downloadFileName]"
        fs_garbageCollect "$downloadFileName"
        # ... and exit
        return $G_RETFAIL
    fi

    # it seems that we've got the file perform some verifications on it
    case "$___g_napiprojekt_napiprojektId" in
        "pynapi" ) # no need to do anything
            ;;

        "other")
            fs_7z_SO x \
                -y -so \
                -p"$g_napiprojektPassword" \
                "$downloadFileName" 2>/dev/null > "$outputFile" || {
                logging_error $"7z zwraca blad. nie mozna rozpakowac napisow"
                [ -e "$outputFile" ] && fs_garbageCollect "$outputFile"
                return $G_RETFAIL
            }
            ;;
    esac

    # check if the file was downloaded successfully by checking
    # if it exists at all
    [ -s "$outputFile" ] || {
        logging_error $"sciagniety plik nie istnieje, nieznany blad"
        [ -e "$outputFile" ] && fs_garbageCollect "$outputFile"
        return $G_RETFAIL
    }

    # count lines in the file
    logging_debug $LINENO $"licze linie w pliku" "[$outputFile]"
    local lines=$(cat "$outputFile" | wrappers_countLines_SO)
    local minLines=3

    logging_debug $LINENO $"lines/minLines:" "[$lines/$minLines]"

    [ "$lines" -lt "$minLines" ] && {
        logging_info $LINENO $"plik uszkodzony. niepoprawna ilosc linii"
        logging_debug $LINENO "[$(<"${outputFile}")]"
        fs_garbageCollect "$outputFile"
        return $G_RETFAIL
    }

    return $G_RETOK
}

#
# @brief: retrieve cover (probably deprecated okladka_pobierz doesn't exist - 404)
# @param: md5sum
# @param: outputfile
#
napiprojekt_downloadCoverLegacy() {
    local videoMd5sum="${1:-}"
    local outputFile="${2:-}"

    local httpCodes=
    local status=

    local url="${g_napiprojektBaseUrl}${g_napiprojektCoverUri}"
    url="${url}?id=${videoMd5sum}&oceny=-1"

    httpCodes=$(http_downloadUrl_SOSE "$url" "$outputFile" 2>&1)
    status=$?

    logging_info $LINENO $"otrzymane odpowiedzi http:" "[$httpCodes] [$status]"

    # shellcheck disable=SC2086
    if [ "$status" -ne $G_RETOK ]; then
        logging_error $"blad wgeta. nie mozna pobrac pliku" "[$outputFile]"
        # ... and exit
        return $G_RETFAIL
    fi

    # if file doesn't exist or has zero size
    [ -s "$outputFile" ] || {
        fs_garbageCollect "$outputFile"
        return $G_RETUNAV
    }

    return $G_RETOK
}

# EOF
