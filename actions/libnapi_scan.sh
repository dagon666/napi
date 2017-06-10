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

# global

#
# global paths list
#
declare -a g_scan_paths=()

#
# global files list
#
declare -a g_scan_files=()

#
# @brief abbreviation
# - string added between the filename and the extension
#
# @brief conversion abbreviation
# - string added between the filename and the extension
#   only for the converted subtitles
#
declare -a ___g_abbrev=( "" "" )

#
# @brief minimum size of files to be processed
#
___g_min_size=0

#
# @brief whether to skip downloading if file is already present
#
___g_skip=0

#
# @brief prepare all the possible filename combinations
#
declare -a ___g_pf=()

#
# controls whether to print statistics on exit or not
#
___g_stats_print=0

# @brief processing stats
# 0 - downloaded
# 1 - unavailable
# 2 - skipped
# 3 - converted
# 4 - covers downloaded
# 5 - covers unavailable
# 6 - covers skipped
# 7 - nfos downloaded
# 8 - nfos unavailable
# 9 - nfos skipped
# 10 - total processed
# 11 - charset converted
declare -a ___g_scan_stats=( 0 0 0 0 0 0 0 0 0 0 0 0 )

########################################################################

#
# @brief scan action arguments dispatcher
#
_scan_argvDispatcher_GV() {
    case "$1" in
        "-c" | "--cover")
            sysconf_setKey_GV napiprojekt.cover.download 1
            ;;

        "-n" | "--nfo")
            sysconf_setKey_GV napiprojekt.nfo.download 1
            ;;

        "-e" | "--ext")
            ___g_argvOutputHandlerType="func"
            ___g_argvOutputHandler='sysconf_setKey_GV napiprojekt.subtitles.extension'
            ___g_argvErrorMsg=$"nie okreslono domyslnego rozszerzenia dla pobranych plikow"
            ;;

        "-b" | "--bigger-than")
            ___g_argvOutputHandlerType="var"
            ___g_argvOutputHandler='___g_min_size'
            ___g_argvErrorMsg=$"nie okreslono minimalnego rozmiaru"
            ;;

        "-a" | "--abbrev")
            ___g_argvOutputHandlerType="var"
            ___g_argvOutputHandler='___g_abbrev[0]'
            ___g_argvErrorMsg=$"nie określono wstawki"
            ;;

        "--conv-abbrev")
            ___g_argvOutputHandlerType="var"
            ___g_argvOutputHandler='___g_abbrev[1]'
            ___g_argvErrorMsg=$"nie określono wstawki dla konwersji"
            ;;

        "-s" | "--skip") ___g_skip=1 ;;
        "--stats") ___g_stats_print=1 ;;
        "-M" | "--move") fs_setCp_GV "mv" ;;

        "-F" | "--forks")
            ___g_argvOutputHandlerType="func"
            ___g_argvOutputHandler='sysconf_setKey_GV system.forks'
            ___g_argvErrorMsg=$"nie określono ilosci watkow"
            ;;

        "-f"|"--format")
            ___g_argvOutputHandlerType="func"
            ___g_argvOutputHandler='sysconf_setKey_GV napiprojekt.subtitles.format'
            ___g_argvErrorMsg=$"nie określono formatu docelowego napisow"
            ;;

        "-o" | "--orig-prefix")
            ___g_argvOutputHandlerType="func"
            ___g_argvOutputHandler='sysconf_setKey_GV napiprojekt.subtitles.orig.prefix'
            ___g_argvErrorMsg=$"nie określono domyslnego prefixu"
            ;;

        "-d" | "--delete-orig")
            logging_debug $LINENO $"ustawiam flage usuwania oryginalow"
            sysconf_setKey_GV napiprojekt.subtitles.orig.delete 1
            ;;

        "-C" | "--charset")
            ___g_argvOutputHandlerType="func"
            ___g_argvOutputHandler='sysconf_setKey_GV napiprojekt.subtitles.encoding'
            ___g_argvErrorMsg=$"nie podano docelowego kodowania"
            ;;

        "-P" | "--pref-fps")
            ___g_argvOutputHandlerType="func"
            ___g_argvOutputHandler='fs_setFpsTool_GV'
            ___g_argvErrorMsg=$"nie określono narzedzia do detekcji fps"
            ;;

        *)
            logging_debug $LINENO $"dodaje sciezke" "[$1]"
            g_scan_paths=( "${g_scan_paths[@]}" "$1" )
            ;;
    esac
}

#
# @brief parse arguments
#
_scan_parseArgv_GV() {
    logging_debug $LINENO $"parsuje opcje akcji scan"
    argv_argvParser_GV _scan_argvDispatcher_GV "$@"
}

#
# @brief prepare a list of file which require processing
#
_scan_prepareFileList() {
    local file=

    for file in "$@"; do
        [ -s "$file" ] || continue

        # check if is a directory
        # if so, then recursively search the dir
        if [ -d "$file" ]; then
            local tmp="$file"
            logging_debug $LINENO $"przeszukuje katalog" "[$file]"
            _scan_prepareFileList "$tmp"/*

        else
            local fileSize=$(fs_stat_SO "$file")
            local sizeLimit=$(( ___g_min_size*1024*1024 ))

            logging_debug $LINENO $"znaleziono plik: " "$file" \
                $", o rozmiarze: " "$fileSize" \
                $", limit: " "$sizeLimit"

            fs_isVideoFile "$file" &&
                [ "${fileSize:-0}" -ge "$sizeLimit" ] && {
                g_scan_files=( "${g_scan_files[@]}" "$file" )
            }
        fi
    done
}

#
# @brief prepare all the possible filenames for the output file (in order to
# check if it already exists)
#
# this function prepares global variables ___g_pf containing all the possible output filenames
# index description
#
# @param video filename (without path)
# @param subtitles format
#
_scan_prepareFileNames() {
    local fileName="${1:-}"
    local noExt=$(wrappers_stripExt_SO "$fileName")
    local defExt=$(subs_getDefaultExtension_SO)
    local convertedSubsExtension=$(subs_getSubFormatExtension_SO "${2}")

    local ab=${___g_abbrev[0]}
    local cab=${___g_abbrev[1]}

    # empty the array
    ___g_pf=()

    # array contents description
    #
    # original_file (o) - as download from napiprojekt.pl (with extension changed only)
    # abbreviation (a)
    # conversion abbreviation (A)
    # prefix (p) - __g_settings_orig_prefix for the original file
    # converted_file (c) - filename with converted subtitles format (may have differect extension)
    #
    # 0 - o - filename + defExt
    # 1 - o + a - filename + abbreviation + defExt
    # 2 - p + o - __g_settings_orig_prefix + filename + defExt
    # 3 - p + o + a - __g_settings_orig_prefix + filename + abbreviation + __g_settings_default_extension
    # 4 - c - filename + get_sub_ext
    # 5 - c + a - filename + abbreviation + get_sub_ext
    # 6 - c + A - filename + conversion_abbreviation + get_sub_ext
    # 7 - c + a + A - filename + abbreviation + conversion_abbreviation + get_sub_ext

    # original
    ___g_pf[0]="${noExt}.${defExt}"
    ___g_pf[1]="${noExt}.${ab:+$ab.}${defExt}"
    ___g_pf[2]="${__g_settings_orig_prefix}${___g_pf[0]}"
    ___g_pf[3]="${__g_settings_orig_prefix}${___g_pf[1]}"

    # converted
    ___g_pf[4]="${noExt}.${convertedSubsExtension}"
    ___g_pf[5]="${noExt}.${ab:+$ab.}${convertedSubsExtension}"
    ___g_pf[6]="${noExt}.${cab:+$cab.}${convertedSubsExtension}"
    ___g_pf[7]="${noExt}.${ab:+$ab.}${cab:+$cab.}${convertedSubsExtension}"
}

#
# @brief check file presence
#
_scan_checkSubsPresence() {
    local mediaFile="$1"
    local path="$2"

    # bits
    # 1 - unconverted available/unavailable
    # 0 - converted available/unavailable
    #
    # default - converted unavailable, unconverted unavailable
    local rv=0

    if [ "$(sysconf_getKey_SO napiprojekt.subtitles.format)" != 'default' ]; then

        # unconverted unavailable, converted available
        rv=$(( rv | 1 ))

        if [ -e "$path/${___g_pf[7]}" ]; then
            logging_status "SKIP" "$mediaFile"

        elif [ -e "$path/${___g_pf[6]}" ]; then
            logging_status "COPY" "${___g_pf[6]} -> ${___g_pf[7]}"
            fs_cp "$path/${___g_pf[6]}" "$path/${___g_pf[7]}"

        elif [ -e "$path/${___g_pf[5]}" ]; then
            logging_status "COPY" "${___g_pf[5]} -> ${___g_pf[7]}"
            fs_cp "$path/${___g_pf[5]}" "$path/${___g_pf[7]}"

        elif [ -e "$path/${___g_pf[4]}" ]; then
            logging_status "COPY" "${___g_pf[4]} -> ${___g_pf[7]}"
            fs_cp "$path/${___g_pf[4]}" "$path/${___g_pf[7]}"

        else
            logging_info $LINENO $"skonwertowany plik niedostepny"
            rv=$(( rv & ~1 ))
        fi

        # we already have what we need - bail out
        [ $(( rv & 1 )) -eq 1 ] && return $rv
    fi

    # assume unconverted available & verify that
    rv=$(( rv | 2 ))

    # when the conversion is not required
    if [ -e "$path/${___g_pf[1]}" ]; then
        logging_status "SKIP" "$mediaFile"

    elif [ -e "$path/${___g_pf[0]}" ]; then
        logging_status "COPY" "${___g_pf[0]} -> ${___g_pf[1]}"
        fs_cp "$path/${___g_pf[0]}" "$path/${___g_pf[1]}"

    elif [ -e "$path/${___g_pf[3]}" ]; then
        logging_status "COPY" "${___g_pf[3]} -> ${___g_pf[1]}"
        fs_cp "$path/${___g_pf[3]}" "$path/${___g_pf[1]}"

    else
        logging_info $LINENO $"oryginalny plik niedostepny"
        rv=$(( rv & ~2 ))
    fi

    # exceptionally in this function return value caries the
    # information - not the execution status
    return $rv
}

#
# @brief process file in legacy mode
#
_scan_downloadAssetsLegacy() {
    local filePath="${1:-}"
    local fileName="${2:-}"
    local fileDir="${3:-}"
    local fileHash="${4:-}"
    local fileSize="${5:-}"
    local lang="${6:-}"
    local subsPath="${7:-}"

    local getNfo=$(sysconf_getKey_SO napiprojekt.nfo.download)
    local getCover=$(sysconf_getKey_SO napiprojekt.cover.download)

    local rv=$G_RETOK

    [ "$getNfo" -eq 1 ] && {
        logging_warning $LINENO $"plik nfo nie jest wspierany w trybie legacy"
    }

    if napiprojekt_downloadSubtitlesLegacy \
        "$fileHash" \
        "$(napiprojekt_f_SO "$fileHash")" \
        "${subsPath}" \
        "${lang}"; then
        logging_success $"napisy pobrano pomyslne" "[$fileName]"

        [ "$getCover" -eq 1 ] && {
            local coverExt=$(sysconf_getKey_SO napiprojekt.cover.extension)
            if napiprojekt_downloadCoverLegacy "$fileHash" \
                "${fileDir}/${fileNameNoExt}.${coverExt}"; then
                logging_success $"okladka pobrana pomyslne" "[$fileName]"
                ___g_scan_stats[4]=$(( ___g_scan_stats[4] + 1 ))
            else
                logging_error $"nie udalo sie pobrac okladki" "[$fileName]"
                ___g_scan_stats[5]=$(( ___g_scan_stats[5] + 1 ))
            fi
        }
    else
        logging_error $"nie udalo sie pobrac napisow" "[$fileName]"
        rv=G_RETUNAV
    fi

    return $rv
}

#
# @brief process file using new XML API
#
_scan_downloadAssetsXml() {
    local filePath="${1:-}"
    local fileName="${2:-}"
    local fileDir="${3:-}"
    local fileHash="${4:-}"
    local fileSize="${5:-}"
    local lang="${6:-}"
    local subsPath="${7:-}"

    local fileNameNoExt="$(wrappers_stripExt_SO "$fileName")"
    local xmlPath="${fileDir}/${fileNameNoExt}.xml"

    local getNfo=$(sysconf_getKey_SO napiprojekt.nfo.download)
    local getCover=$(sysconf_getKey_SO napiprojekt.cover.download)

    local rv=$G_RETOK

    logging_debug $LINENO $"plik xml" "[$xmlPath]"
    fs_garbageCollectUnexisting "$xmlPath"

    if napiprojekt_downloadXml \
        "$fileHash" "$fileName" "$fileSize" "$xmlPath" "$lang" &&
        napiprojekt_verifyXml "$xmlPath"; then
        logging_debug $LINENO $"XML pobrany pomyslnie"

        if napiprojekt_extractSubsFromXml "$xmlPath" "$subsPath"; then
            logging_success $"napisy pobrano pomyslnie" "[$fileName]"

            [ "$getNfo" -eq 1 ] && {
                local nfoExt=$(sysconf_getKey_SO \
                    napiprojekt.nfo.extension)
                logging_debug $LINENO $"tworze plik nfo"

                if napiprojekt_extractNfoFromXml "$xmlPath" \
                    "${fileDir}/${fileNameNoExt}.${nfoExt}"; then
                    logging_success $"plik nfo utworzony pomyslnie" "[$fileName]"
                    ___g_scan_stats[7]=$(( ___g_scan_stats[7] + 1 ))
                else
                    logging_error $"nie udalo sie utworzyc pliku nfo" "[$fileName]"
                    ___g_scan_stats[8]=$(( ___g_scan_stats[8] + 1 ))
                fi
            }

            [ "$getCover" -eq 1 ] && {
                local coverExt=$(sysconf_getKey_SO \
                    napiprojekt.cover.extension)
                logging_debug $LINENO $"wypakowuje okladke z XML"

                if napiprojekt_extractCoverFromXml "$xmlPath" \
                    "${fileDir}/${fileNameNoExt}.${coverExt}"; then
                    logging_success $"okladka pobrana pomyslnie" "[$fileName]"
                    ___g_scan_stats[4]=$(( ___g_scan_stats[4] + 1 ))
                else
                    logging_error $"nie udalo sie pobrac okladki" "[$fileName]"
                    ___g_scan_stats[5]=$(( ___g_scan_stats[5] + 1 ))
                fi
            }
        else
            rv=$G_RETUNAV
        fi
    else
        logging_error $"Blad podczas pobierania, lub XML uszkodzony" \
            "[$fileName]"
        rv=$G_RETUNAV
    fi

    return $rv
}

_scan_downloadAssetsForFile() {
    local filePath="${1:-}"
    local fileName="${2:-}"
    local fileDir="${3:-}"
    local fileHash="${4:-}"
    local fileSize="${5:-}"
    local lang="${6:-}"
    local subsPath="${7:-}"

    local processFunction="_scan_downloadAssetsXml"
    napiprojekt_isNapiprojektIdLegacy &&
        processFunction="_scan_downloadAssetsLegacy"

    logging_debug $LINENO $"uzywam API" "[$processFunction]"

    "$processFunction" \
            "$filePath" \
            "$fileName" \
            "$fileDir" \
            "$fileHash" \
            "$fileSize" \
            "$lang" \
            "$subsPath"
}

#
# @brief process file dispatch
#
_scan_obtainFile() {
    local filePath="${1:-}"
    local lang="${2:-}"
    local format="${3:-}"

    local fileName="$(basename "$filePath")"
    local fileDir="$(dirname "$filePath")"
    local fileSize=$(fs_stat_SO "$filePath")
    local fileHash=$(napiprojekt_calculateMd5VideoFile_SO "$filePath")

    local rv=$RET_OK

    logging_debug $LINENO $"plik" "[$fileName]" \
        $", rozmiar:" "[$fileSize]" \
        $", hash:" "[$fileHash]"

    _scan_prepareFileNames "$fileName" "$format"
    logging_debug $LINENO $"potencjalne nazwy plikow:" "${___g_pf[*]}"
    logging_debug $LINENO $"katalog docelowy" "[$fileDir]"

    local fileAvailability=0

    [ "$___g_skip" -eq 1 ] && {
        logging_debug $LINENO $"sprawdzam dostepnosc pliku"
        _scan_checkSubsPresence "$filePath" "$fileDir"
        fileAvailability=$?
    }

    logging_info $LINENO $"dostepnosc pliku" "$fileAvailability"
    logging_debug $LINENO $"przekonwertowany dostepny" "$(( fileAvailability & 1 ))"
    logging_debug $LINENO $"oryginalny dostepny" "$(( (fileAvailability & 2) >> 1 ))"

    # if conversion is requested
    if [ "$format" != 'default' ]; then
        local shouldConvert=0
        case "$fileAvailability" in
            0) # download & convert
                if _scan_downloadAssetsForFile \
                    "$filePath" \
                    "$fileName" \
                    "$fileDir" \
                    "$fileHash" \
                    "$fileSize" \
                    "$lang" \
                    "$fileDir/${___g_pf[1]}"; then
                    logging_debug $LINENO $"napisy pobrano, nastapi konwersja"
                    shouldConvert=1
                    ___g_scan_stats[0]=$(( ___g_scan_stats[0] + 1 ))
                else
                    # unable to get the file
                    logging_debug $LINENO $"napisy niedostepne"
                    rv=$G_RETUNAV
                fi
            ;;

            1) # unconverted unavailable, converted available
                logging_debug $LINENO $"nie pobieram, nie konwertuje - dostepna skonwertowana wersja"
                # increment skipped counter
                ___g_scan_stats[2]=$(( ___g_scan_stats[2] + 1 ))
                rv=$G_RETNOACT
            ;;

            2|3) # convert
                logging_debug $LINENO "nie pobieram - dostepna jest nieskonwertowana wersja"
                # increment skipped counter
                ___g_scan_stats[2]=$(( ___g_scan_stats[2] + 1 ))
                shouldConvert=1
            ;;
        esac

        # original file available - convert it
        if [ "$shouldConvert" -eq 1 ]; then
            logging_msg $"konwertowanie do formatu" "$format"
            subs_convertFormat \
                "$filePath" \
                "$fileDir" \
                "${___g_pf[1]}" \
                "${___g_pf[3]}" \
                "${___g_pf[7]}" &&
                ___g_scan_stats[3]=$(( ___g_scan_stats[3] + 1 ))
        fi
    else
        logging_info $LINENO $"konwersja nie jest wymagana"

        # file is not available - download
        if [ ${fileAvailability[0]} -eq 0 ]; then
            if _scan_downloadAssetsForFile \
                "$filePath" \
                "$fileName" \
                "$fileDir" \
                "$fileHash" \
                "$fileSize" \
                "$lang" \
                "$fileDir/${___g_pf[1]}"; then
                ___g_scan_stats[0]=$(( ___g_scan_stats[0] + 1 ))
            else
                rv=$G_RETUNAV
            fi
        else
            # increment skipped counter
            ___g_scan_stats[2]=$(( ___g_scan_stats[2] + 1 ))
            rv=$G_RETNOACT
        fi
    fi

    return $rv
}

_scan_processFile() {
    local filePath="${1:-}"
    local fileName="$(basename "$filePath")"
    local lang="${2:-}"
    local format="${3:-}"
    local status=$G_RETOK
    local rv=$G_RETOK

    # name with abbreviation by default
    local fileNameIndex=1

    _scan_obtainFile "$filePath" "$lang" "$format"
    status=$?

    if [ "$status" -eq "$G_RETOK" ] ||
        [ "$status" -eq "$G_RETNOACT" ]; then

        [ "$format" != 'default' ] && {
            logging_debug $LINENO $"zadanie konwersji - korekcja nazwy pliku"
            fileNameIndex=7
        }

        local charset="$(sysconf_getKey_SO napiprojekt.subtitles.encoding)"
        local path="$(dirname "$filePath")"

        [ "${charset:-default}" != 'default' ] &&
            [ "$status" -eq "$G_RETOK" ] && {
            if subs_convertEncoding \
                "${path}/${___g_pf[$fileNameIndex]}" \
                "$charset"; then
                ___g_scan_stats[11]=$(( ___g_scan_stats[11] + 1 ))
            else
                logging_error $"konwersja kodowania niepomyslna"
            fi
        }

        hooks_callHook_GV "${path}/${___g_pf[$fileNameIndex]}"

    else
        # unav counter
        ___g_scan_stats[1]=$(( ___g_scan_stats[1] + 1 ))
        rv=$G_RETUNAV
    fi

    # increment total processed counter
    ___g_scan_stats[10]=$(( ${___g_scan_stats[10]} + 1 ))
    logging_debug $LINENO $"przetwarzanie zakonczone dla" "[$fileName]"
    return $rv
}

#
# @brief this is a worker function it will run over the files array with a
# given step starting from given index
# @param starting index
# @param increment
#
_scan_processFiles() {
    local startIdx="${1:-}"
    local increment="${2:-}"

    local lang="$(language_getLanguage_SO)"
    local format=$(sysconf_getKey_SO napiprojekt.subtitles.format)

    # current
    local c="$startIdx"

    while [ "$c" -lt ${#g_scan_files[@]} ]; do
        logging_info $LINENO "#$startIdx - index poczatkowy $c"
        _scan_processFile "${g_scan_files[$c]}" "$lang" "$format"
        c=$(( c + increment ))
    done

    # dump statistics to fd #8 (if it has been opened before)
    [ -e "/proc/self/fd/8" ] || [ -e "/dev/fd/8" ] &&
        echo "${___g_scan_stats[*]}" >&8
}

#
# @brief summarize statistics collected from forks
# @param statistics file
#
_scan_sumStats() {
    local file="$1"
    local awkScript=''
    local fc=${#___g_scan_stats[@]}

# embed small awk program to count the columns
read -d "" awkScript << EOF
BEGIN {
    fmax=$fc
    for (x=0; x<fmax; x++) cols[x] = 0
}
{
    max = fmax > NF ? NF : fmax
    for (x=0; x<max; x++) cols[x] += \$(x + 1)
}
END {
    for (x=0; x<fmax; x++)
        printf "%d ", cols[x]
    print ""
}
EOF
    # update the contents
    ___g_scan_stats=( $(awk "$awkScript" "$file") )
}

#
# print stats summary
#
_scan_printStats() {
    declare -a labels=( 'OK' 'UNAV' 'SKIP' \
        'CONV' 'COVER_OK' 'COVER_UNAV' \
        'COVER_SKIP' 'NFO_OK' 'NFO_UNAV' 'NFO_SKIP' 'TOTAL' 'CONV_CHARSET' )
    local i=0
    logging_msg $"statystyki przetwarzania"
    while [ $i -lt "${#___g_scan_stats[@]}" ]; do
        logging_status "${labels[$i]}" "${___g_scan_stats[$i]}"
        i=$(( i + 1 ))
    done
}

#
# @brief spawn new processes and process files
#
_scan_spawnForks() {
    local c=0
    local nForks="$(sysconf_getKey_SO system.forks)"
    local oldMsgCnt=0
    local statsFile="$(fs_mktempFile_SO)"

    # open fd #8 (selected arbitrarily) for statistics collection
    exec 8<> "$statsFile"

    # spawn parallel processing
    while [ $c -lt "$nForks" ] && [ $c -lt ${#g_scan_files[@]} ]; do
        logging_debug $LINENO $"nowy fork" "[$c/->$nForks]"
        logging_setForkId $(( c + 1 ))

        oldMsgCnt=$(logging_getMsgCounter_SO)
        logging_setMsgCounter 1 # reset message counter

        # fork
        _scan_processFiles "$c" "$nForks" &

        # restore original values
        logging_setMsgCounter "$oldMsgCnt"

        c=$(logging_getForkId_SO)
        logging_setForkId 0
    done

    # wait for all forks
    wait

    # sum stats data
    if [ -e "$statsFile" ]; then
        _scan_sumStats "$statsFile"
        # close the fd
        exec 8>&-
    fi

    # restore main fork id
    logging_setForkId 0
}

#
# @brief scan files and download subtitles
#
_scan_getSubtitlesForFiles() {
    logging_info $LINENO $"przygotowuje liste plikow..."

    _scan_prepareFileList "${g_scan_paths[@]}"
    logging_msg "znaleziono ${#g_scan_files[@]} plikow..."

    _scan_spawnForks
}

########################################################################

#
# @brief print usage description for subtitles action
#
scan_usage() {
    echo $"napi.sh scan [OPCJE] <plik|katalog|*>"
    echo
    echo $"OPCJE:"
    echo $" -c | --cover - pobierz okladke"
    echo $" -n | --nfo - utworz plik z informacjami o napisach"
    echo $" -e | --ext - rozszerzenie dla pobranych napisow (domyslnie *.txt)"
    echo $" -b | --bigger-than <size MB> - skanuj pliki wieksze niz <size>"

    echo $" -F | --forks - okresl recznie ile rownoleglych procesow utworzyc"
    echo $" -M | --move - w przypadku opcji (-s) przenos pliki, nie kopiuj"
    echo $" -a | --abbrev <string> - dodaj dowolny string przed rozszerzeniem (np. nazwa.<string>.txt)"
    echo $"    | --conv-abbrev <string> - dodaj dowolny string przed rozszerzeniem podczas konwersji formatow"
    echo $" -s | --skip - nie sciagaj, jezeli napisy juz sciagniete"
    echo $"    | --stats - wydrukuj statystyki (domyslnie nie beda drukowane)"
    echo $" -o | --orig-prefix - prefix dla oryginalnego pliku przed konwersja"
    echo $" -d | --delete-orig - Delete the original file"
    echo $" -f | --format - konwertuj napisy do formatu (wym. subotage.sh)"
    echo $" -P | --pref-fps <fps_tool> - preferowany detektor fps (jezeli wykryto jakikolwiek)"
    echo
    echo "Obslugiwane formaty konwersji napisow"
    # TODO get rid of this and replace with a subs_ library call
    subotage.sh -gl

    tools_isDetected "iconv" &&
        echo $" -C | --charset - konwertuj kodowanie plikow (iconv -l - lista dostepnych kodowan)"

    local countFps=$(tools_countDetectedGroupMembers_SO "fps")

    if [ "$countFps" -gt 0 ]; then
        echo $"Wykryte narzedzia detekcji FPS" "($countFps)"
    else
        echo
        echo $"By moc okreslac FPS na podstawie pliku video a nie na"
        echo $"podstawie pierwszej linii pliku (w przypadku konwersji z microdvd)"
        echo $"zainstaluj dodatkowo jedno z tych narzedzi (dowolne)"
        echo
    fi
    tools_groupToList_SO "fps"

    echo
    echo "Przyklady:"
    echo " napi.sh film.avi          - sciaga napisy dla film.avi."
    echo " napi.sh -c film.avi       - sciaga napisy i okladke dla film.avi."
    echo " napi.sh -u foo -p bar -c film.avi - sciaga napisy i okladke do"
    echo "                             film.avi jako uzytkownik foo"
    echo " napi.sh *                 - szuka plikow wideo w obecnym katalogu"
    echo "                             i podkatalogach, po czym stara sie dla"
    echo "                             nich znalezc i pobrac napisy."
    echo " napi.sh *.avi             - wyszukiwanie tylko plikow avi."
    echo " napi.sh katalog_z_filmami - wyszukiwanie we wskazanym katalogu"
    echo "                             i podkatalogach."
    echo " napi.sh -f subrip *       - sciaga napisy dla kazdego znalezionego pliku"
    echo "                           po czym konwertuje je do formatu subrip"
}

#
# @brief entry point for search action
#
scan_main() {
    # parse search specific options
    _scan_parseArgv_GV "$@" || {
        logging_debug $"blad parsera scan"
        return $G_RETFAIL
    }

    # process hashes
    _scan_getSubtitlesForFiles
    [ "$___g_stats_print" -eq 1 ] && _scan_printStats
    return $G_RETOK
}

# EOF
