#!/bin/bash

########################################################################
########################################################################
########################################################################

#  Copyright (C) 2010 Tomasz Wisniewski aka DAGON <tomasz.wisni3wski@gmail.com>
#  http://www.dagon.bblog.pl
#  http://hekate.homeip.net
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


# napi project user/password configuration
# (may be left blank)
g_User=""
g_Pass=""
g_NapiPass="iBlm8NTigvru0Jr0"
g_Lang="PL"

#system detection
g_System=$(uname | tr '[:upper:]' '[:lower:]')

if [ $g_System = "darwin" ]; then 
    g_Md5="md5"
    g_StatParams="-f%z "
else
    g_Md5="md5sum"
    g_StatParams="-c%s "
fi


# supported video file extentions
declare -a g_VideoUris=( 'avi' 'rmvb' 'mov' 'mp4' 'mpg' 'mkv' 'mpeg' 'wmv' )

# list of all mandatory to basic functionality tools
declare -a g_MandatoryTools=(  $g_Md5 'tr' 'printf' 
                    'wget' 'find' 'dd' 
                    'grep' 'sed' 'cut' 'seq' )

# language code arrays
declare -a g_Language=( 'Albański' 'Angielski' 'Arabski' 'Bułgarski' 
        'Chiński' 'Chorwacki' 'Czeski' 'Duński' 
        'Estoński' 'Fiński' 'Francuski' 'Galicyjski' 
        'Grecki' 'Hebrajski' 'Hiszpanski' 'Holenderski' 
        'Indonezyjski' 'Japoński' 'Koreański' 'Macedoński' 
        'Niemiecki' 'Norweski' 'Oksytański' 'Perski' 
        'Polski' 'Portugalski' 'Portugalski' 'Rosyjski' 
        'Rumuński' 'Serbski' 'Słoweński' 'Szwedzki' 
        'Słowacki' 'Turecki' 'Wietnamski' 'Węgierski' 'Włoski' )

declare -a g_LanguageCodes2L=( 'SQ' 'EN' 'AR' 'BG' 'ZH' 'HR' 'CS' 'DA' 'ET' 'FI' 
                    'FR' 'GL' 'EL' 'HE' 'ES' 'NL' 'ID' 'JA' 'KO' 'MK' 
                    'DE' 'NO' 'OC' 'FA' 'PL' 'PT' 'PB' 'RU' 'RO' 'SR' 
                    'SL' 'SV' 'SK' 'TR' 'VI' 'HU' 'IT' )

declare -a g_LanguageCodes3L=( 'ALB' 'ENG' 'ARA' 'BUL' 'CHI' 'HRV' 'CZE' 
                    'DAN' 'EST' 'FIN' 'FRE' 'GLG' 'ELL' 'HEB' 
                    'SPA' 'DUT' 'IND' 'JPN' 'KOR' 'MAC' 'GER' 
                    'NOR' 'OCI' 'PER' 'POL' 'POR' 'POB' 'RUS' 
                    'RUM' 'SCC' 'SLV' 'SWE' 'SLO' 'TUR' 'VIE' 'HUN' 'ITA' )

# if pynapi is not acceptable then use "other" - in this case p7zip is 
# required to finish processing
g_Revison="v1.1.13"
g_Version="pynapi"
#g_Version="other"

# global file list
declare -a g_FileList=( )
declare -a g_Formats=( )
declare -a g_Params=( )

g_Cover=""
g_Skip=0
g_Format="no_conversion"
g_Abbrev=""
g_ConvAbbrev=""
g_Script=""
g_Charset=""
g_DeleteIntermediate=true

# subotage presence indicator
g_SubotagePresence=0

# iconv presence
g_IconvPresence=0

# fps detection tools: mediainfo mplayer
g_FpsTool=""
g_Fps=0
g_LogFile="none"

# default extension
g_DefaultExt="txt"

# minimum size
g_MinimumSize=0;

# statistical data
g_Skipped=0
g_Downloaded=0
g_Unavailable=0

########################################################################
########################################################################
########################################################################

display_help() {
    echo "=============================================================="
    echo "napi.sh version $g_Revison (identifies as $g_Version)"
    echo "napi.sh [OPCJE] <plik|katalog|*>"
    echo "   -c | --cover - pobierz okladke"

    if [[ $g_IconvPresence -eq 1 ]]; then    
        echo "   -C | --charset - konwertuj kodowanie plikow (iconv -l - lista dostepnych kodowan)"
    fi

    echo "   -b | --bigger-than <size MB> - szukaj napisow tylko dla plikow wiekszych niz <size>"
    echo "   -e | --ext - rozszerzenie dla pobranych napisow (domyslnie *.txt)"
    echo "   -s | --skip - nie sciagaj, jezeli napisy juz sciagniete"
    echo "   -u | --user <login> - uwierzytelnianie jako uzytkownik"
    echo "   -p | --pass <passwd> - haslo dla uzytkownika <login>"
    echo "   -L | --language <LANGUAGE_CODE> - pobierz napisy w wybranym jezyku"
    echo "   -l | --log <logfile> - drukuj output to pliku zamiast na konsole"
    echo "   -a | --abbrev <string> - dodaj dowolny string przed rozszerzeniem (np. nazwa.<string>.txt)"
    echo "   -S | --script <script_path> - wywolaj skrypt po pobraniu napisow (sciezka do pliku z napisami, relatywna do argumentu napi.sh, bedzie przekazana jako argument)"
        
    if [[ $g_SubotagePresence -eq 1 ]]; then    
        echo "   -f | --format - konwertuj napisy do formatu (wym. subotage.sh)"
		echo "      | --save-orig - nie kasuj oryginalnego pliku txt sprzed konwersji"   
		echo "      | --conv-abbrev <string> - dodaj dowolny string przed rozszerzeniem podczas konwersji formatow"                             
    fi
        
    echo "=============================================================="
    echo
    if [[ $g_SubotagePresence -eq 1 ]]; then    
        echo "Obslugiwane formaty konwersji napisow"
        subotage.sh -gl
        echo
    fi

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
        
    if [[ $g_SubotagePresence -ne 1 ]]; then
        echo " "
        echo "UWAGA !!!"
        echo "napi.sh moze automatycznie dokonywac konwersji napisow"
        echo "do wybranego przez Ciebie formatu. Zainstaluj uniwersalny"
        echo "konwerter formatow dla basha: subotage.sh"
        echo "http://sourceforge.net/projects/subotage/"
        echo
    else
        echo " napi.sh -f subrip *       - sciaga napisy dla kazdego znalezionego pliku"
        echo "                           po czym konwertuje je do formatu subrip"
    
        if [[ -z $g_FpsTool ]]; then 
            echo
            echo "By moc okreslac FPS na podstawie pliku video a nie na"
            echo "podstawie pierwszej linii pliku (w przypadku konwersji z microdvd)"
            echo "zainstaluj dodatkowo jedno z tych narzedzi (dowolnie ktore)"
            echo -e "- mediainfo\n- mplayer\n- ffmpeg\n"
            echo
        fi
    fi
}


#
# @brief: list all the supported languages and their respective 2/3 letter codes
#
list_languages() {
    local i=0
    while [[ $i -lt ${#g_Language[@]} ]]; do
        echo "${g_LanguageCodes2L[$i]}/${g_LanguageCodes3L[$i]} - ${g_Language[$i]}"
        i=$(( $i + 1 ))
    done
}


#
# @brief verify that the given language code is supported
#
check_language() {
    local lang="$1"
    declare -a local l_arr=(  )
    local l_arr_name=""
    local i=0
    
    if [[ ${#lang} -ne 2 ]] && [[ ${#lang} -ne 3 ]]; then
        return
    fi

    l_arr_name="g_LanguageCodes${#lang}L";
    eval l_arr=\( \${${l_arr_name}[@]} \)

    while [[ $i -lt ${#l_arr[@]} ]]; do
        if [[ "${l_arr[$i]}" = "$lang" ]]; then
            echo "$i"
            return
        fi
        i=$(( $i + 1 ))
    done
}

#
# @brief set the language variable
# @param: language index
#
set_language() {
    declare -a local lang=${g_LanguageCodes2L[$1]}

    # don't ask me why
    if [[ $lang = "EN" ]]; then
        lang="ENG"
    fi

    g_Lang="$lang"
}


#
# @brief: check if the given file is a video file
# @param: video filename
# @return: bool 1 - is video file, 0 - is not a video file
#
check_extention() {
    local is_video=0  
    local filename=$(basename "$1")
    local extention=$(echo "${filename##*.}" | tr '[A-Z]' '[a-z]')
    local ext

    for ext in "${g_VideoUris[@]}"; do
        if [[ "$ext" = "$extention" ]]; then
            is_video=1
            break
        fi
    done
    
    echo $is_video
}



#
# @brief: mysterious f() function
# @param: md5sum
#
f() {
    declare -a local t_idx=( 0xe 0x3 0x6 0x8 0x2 )
    declare -a local t_mul=( 2 2 5 4 3 )
    declare -a local t_add=( 0 0xd 0x10 0xb 0x5 )
    local sum="$1"
    local b=""    
    local i=0

    # for i in {0..4}; do
    for i in $(seq 0 4); do
        local a=${t_add[$i]}
        local m=${t_mul[$i]}
        local g=${t_idx[$i]}        
        
        local t=$(( a + 16#${sum:$g:1} ))
        local v=$(( 16#${sum:$t:2} ))
        
        local x=$(( (v*m) % 0x10 ))
        local z=$(printf "%X" $x)
        b="$b$(echo $z | tr '[A-Z]' '[a-z]')"
    done
    echo "$b"
}


#
# @brief: retrieve subtitles
# @param: md5sum
# @param: hash
# @param: outputfile
#
get_subtitles() {   
    local url="http://napiprojekt.pl/unit_napisy/dl.php?l=$g_Lang&f=$1&t=$2&v=$g_Version&kolejka=false&nick=$g_User&pass=$g_Pass&napios=posix"

    if [[ $g_Version = "other" ]]; then
        wget -q -O napisy.7z "$url"
        
        if [[ -z "$(builtin type -P 7z)" ]]; then
            f_print_error "7zip jest niedostepny\nzmodyfikuj zmienna g_Version tak by napi.sh identyfikowal sie jako \"pynapi\"" 
            exit
        fi
                
        7z x -y -so -p"$g_NapiPass" napisy.7z 2> /dev/null > "$3"
        rm -rf napisy.7z
    
        if [[ -s "$3" ]]; then
            echo "1"
        else
            echo "0"
            rm -rf "$3"     
        fi
    else
        wget -q -O "$3" "$url"
        local size=$(stat $g_StatParams "$3")
    
        if [[ $size -le 4 ]]; then
            echo "0"
            rm -rf "$3"
        else
            echo "1"            
        fi
    fi      
}


#
# @brief: retrieve cover
# @param: md5sum
# @param: outputfile
#
get_cover() {
    local url="http://www.napiprojekt.pl/okladka_pobierz.php?id=$1&oceny=-1"
    wget -q -O "$2" "$url"
}


#
# @brief prepare a list of file which require processing
# @param space delimited file list string
#
prepare_file_list() {
    local file=""
    for file in "$@"; do

        # check if file exists, if not skip it
        if [[ ! -e "$file" ]]; then
            continue

        elif [[ ! -s "$file" ]]; then
            echo -e "[EMPTY]\t[\"$file\"]:\tPodany plik jest pusty !!!"
            continue

        # check if is a directory
        # if so, then recursively search the dir
        elif [[ -d "$file" ]]; then
            local tmp="$file"
            prepare_file_list "$tmp"/*

        else
            # check if the respective file is a video file (by extention)       
            if [[ $(check_extention "$file") -eq 1 ]] &&
               [[ $(stat $g_StatParams "$file") -ge $(( $g_MinimumSize*1024*1024 )) ]]; then
                g_FileList=( "${g_FileList[@]}" "$file" )
            fi

        fi
    done
}

#
# @brief try to download subs for all the files present in the list
#
download_subs() {   
    local file=""

    if [[ ${#g_FileList[*]} -gt 0 ]]; then
        echo "Pobieram napisy..."
    fi
        
    for file in "${g_FileList[@]}"; do
        
        # input/output filename manipulation
        local base=$(basename "$file")
        local output_path=$(dirname "$file")
        local output_file_noext="${base%.*}"

        # jezeli ustawiona wstawka, to dodaje
        if [[ "$g_Abbrev" != "" ]]; then
            echo "Dodaje '$g_Abbrev' do rozszerzenia"
            output_file_noext="${output_file_noext}.${g_Abbrev}"
        fi

        local output_file="$output_file_noext.$g_DefaultExt"
        local output="$output_path/$output_file"
        local conv_output="$output_path/ORIG_$output_file"
		local final_output="$output"
        local output_img="$output_path/${base%.*}.jpg"
        local fExists=0
		
        case "$g_Format" in
        "subrip")
            final_output="$output_path/${output_file_noext}.${g_ConvAbbrev:+$g_ConvAbbrev.}srt"
            ;;
                
        "subviewer")
            final_output="$output_path/${output_file_noext}.${g_ConvAbbrev:+$g_ConvAbbrev.}sub"
            ;;
		*)
        	final_output="$output_path/${output_file_noext}.${g_ConvAbbrev:+$g_ConvAbbrev.}$g_DefaultExt"
			;;
		esac
		
        if [[ -e "$output" ]] || [[ -e "$final_output" ]]; then
            fExists=1
        fi

        if [[ $fExists -eq 1 ]] && [[ $g_Skip -eq 1 ]]; then    
            echo -e "[SKIP]\t[$final_output]:\tPlik z napisami juz istnieje !!!"
            g_Skipped=$(( $g_Skipped + 1 ))
            continue    
        else
            # md5sum and hash calculation
            local sum=$(dd if="$file" bs=1024k count=10 2> /dev/null | $g_Md5 | cut -d ' ' -f 1)
            local hash=$(f $sum)        
            local napiStatus=$(get_subtitles $sum $hash "$output")
            
            if [[ $napiStatus = "1" ]]; then
                echo -e "[OK]\t[$base]:\tNapisy pobrano pomyslnie !!!"
                g_Downloaded=$(( $g_Downloaded + 1 ))
                    
                # conversion to different format requested
                if [[ $g_SubotagePresence -eq 1 ]] && [[ $g_Format != "no_conversion" ]]; then
                    local outputSubs=""
                    local subotage_c2=""

                    echo " -- Konwertuje napisy do formatu: [$g_Format]"
                
                    # determine the output extention and the output filename
                    # if ext == $g_DefaultExt then copy the original with a ORIG_ prefix
					if [[ "$output" == "$final_output" ]]; then
                        cp "$output" "$conv_output"
                        outputSubs="$output"
                        output="$conv_output"
					else
						outputSubs="$final_output"
					fi
                                                                    
                    f_detect_fps "$file"
                    if [[ "$g_Fps" != "0" ]]; then
                        echo " -- FPS okreslony na podstawie pliku wideo: [$g_Fps]"
                        subotage_c2="-fi $g_Fps"
                    else
                        echo " -- Nie udalo sie okreslic Fps. Okreslam na podstawie pliku napisow lub przyjmuje dom. wart."
                        subotage_c2=""
                    fi
                            
                    echo " -- Wolam subotage.sh"
                    subotage.sh -i "$output" -of $g_Format -o "$outputSubs" $subotage_c2

                    # remove the old format if conversion was successful
                    [[ $? -eq 0 ]] && [[ "$output" != "$outputSubs" ]] && [[ $g_DeleteIntermediate == true ]] && rm -f "$output"
                    output="$outputSubs"
                fi # [[ $g_SubotagePresence -eq 1 ]] && [[ $g_Format != "no_conversion" ]]

                # charset conversion
                if [[ $g_IconvPresence -eq 1 ]] && [[ $g_Charset != "" ]]; then
                    echo " -- Konwertuje kodowanie"
                    local tmp=`mktemp -t napi.XXXXXXXXXX`
                    iconv -f WINDOWS-1250 -t $g_Charset "$output" > $tmp
                    mv $tmp "$output"
                fi # [[ $g_IconvPresence -eq 1 ]] && [[ $g_Charset != "" ]]

				if [[ $g_Script != "" ]]; then
					echo " -- Wolam: $g_Script \"$output\""
					$g_Script "$output"
				fi

            else # [[ $napiStatus = "1" ]]
                    echo -e "[UNAV]\t[$base]:\tNapisy niedostepne !!!"
                    g_Unavailable=$(( $g_Unavailable + 1 ))
                    continue
            fi # [[ $napiStatus = "1" ]]
                
            if [[ $g_Cover = "1" ]]; then
                get_cover "$sum" "$output_img"
            fi

        fi # [[ $fExists -eq 1 ]] && [[ $g_Skip -eq 1 ]]
    done    
}


#
# @brief check if subotage.sh is installed and available
#
f_check_for_subotage() {
    if [[ -n $(builtin type -P subotage.sh) ]]; then
        g_SubotagePresence=1
    fi
}


#
# @brief check if ifconv is installed and available
#
f_check_for_iconv() {
    if [[ -n $(builtin type -P iconv) ]]; then
        g_IconvPresence=1
    fi
}


#
# @brief check for FPS detection tools
#
f_check_for_fps_detectors() {
    if [[ -n $(builtin type -P mediainfo) ]]; then
        g_FpsTool="mediainfo \"{}\" | grep -i 'frame rate' | tr -d '[\r a-zA-Z:]'"        
    elif [[ -n $(builtin type -P mplayer2) ]]; then    
        g_FpsTool="mplayer2 -identify -vo null -ao null -frames 0 \"{}\" 2> /dev/null | grep ID_VIDEO_FPS | cut -d '=' -f 2"
    elif [[ -n $(builtin type -P mplayer) ]]; then    
        g_FpsTool="mplayer -identify -vo null -ao null -frames 0 \"{}\" 2> /dev/null | grep ID_VIDEO_FPS | cut -d '=' -f 2"
    elif [[ -n $(builtin type -P ffmpeg) ]]; then
        g_FpsTool="ffmpeg -i \"{}\" 2>&1 | grep \"Video:\" | sed 's/, /\n/g' | grep fps | cut -d ' ' -f 1"
    fi
}

# @brief error wrapper
f_print_error() {
   if [[ "$g_LogFile" != "none" ]]; then   
      echo -e "$@"
   else
      echo -e "$@" > /dev/stderr
   fi
}

# @brief detect fps from video file
f_detect_fps() {
   if [[ -n $g_FpsTool ]]; then
        echo "Okreslam FPS na podstawie pliku video"
        local cmd=${g_FpsTool/\{\}/"$1"}                
        local tmpFps=$(eval $cmd)
        
        if [[ $(echo $tmpFps | sed -r 's/^[0-9]+[0-9.]*$/success/') = "success" ]]; then
            g_Fps=$tmpFps
        fi      
    else
        echo -e "Brak narzedzi do wykrywania FPS.\nFPS zostanie okreslony na podstawie pliku napisow, lub przyjmie sie wartosc domyslna."
    fi
}

# scan if all needed tools are available
f_check_mandatory_tools() {
    local elem=""

    for elem in "${g_MandatoryTools[@]}"; do
        if [[ -z "$(builtin type -P $elem)" ]]; then
            f_print_error "BLAD !!!\n\n[${elem}] jest niedostepny, skrypt nie bedzie dzialal poprawnie.\nZmodyfikuj zmienna PATH tak by zawierala wlasciwa sciezke do narzedzia\n"
            exit
        fi  
    done    
}

########################################################################
########################################################################
########################################################################

# initialisation
f_check_for_subotage
f_check_for_iconv
f_check_for_fps_detectors


if [[ $g_SubotagePresence -eq 1 ]]; then
    g_Formats=( $(subotage.sh -gf) )
fi

# if no arguments are given, then print help and exit
if [[ $# -lt 1 ]] || [[ $1 = "--help" ]] || [[ $1 = "-h" ]]; then
    f_check_mandatory_tools
    display_help
    exit
fi


# command line arguments parsing
while [ $# -gt 0 ]; do

    case "$1" in
        # cover download
        "-c" | "--cover")
        g_Cover=1
        ;;

        # charset conversion
        "-C" | "--charset")
        shift
        if [[ -z "$1" ]]; then
            f_print_error "Nie podano docelowego kodowania"
            exit
        fi
        g_Charset="$1"
        ;;

        # skip flag
        "-s" | "--skip")
        g_Skip=1
        ;;
        
        # user login
        "-u" | "--user")        
        shift
        if [[ -z "$1" ]]; then
            f_print_error "Nie podano nazwy uzytkownika"
            exit
        fi
        g_User="$1"
        ;;
        
        # password
        "-p" | "--pass")
        shift
                
        if [[ -z "$1" ]]; then
            f_print_error "Nie podano hasla dla uzytkownika [$g_User]"
            exit
        fi      
        g_Pass="$1"     
        ;;

        # extension
        "-e" | "--ext")
        shift
        if [[ -z "$1" ]]; then
            f_printf_error "Nie okreslono domyslnego rozszerzenia dla pobranych plikow"
            exit
        fi
        g_DefaultExt="$1"
        ;;

        "-b" | "--bigger-than")
        shift
        if [[ -z "$1" ]]; then
            f_printf_error "Nie okreslono minimalnego rozmiaru"
            exit
        fi
        g_MinimumSize="$1"
        ;;


        # logfile
        "-l" | "--log")
        shift
        if [[ -z "$1" ]]; then
            f_print_error "Nie podano nazwy pliku dziennika"
            exit        
        fi
        g_LogFile="$1"           
        ;;

        # languages
        "-L" | "--language")
        shift
        if [[ -z "$1" ]]; then
            f_print_error "Wybierz jeden z dostepnych 2/3 literowych kodow jezykowych"
            list_languages
            exit        
        fi

        tmp=$(check_language "$1")
        if [[ -n "$tmp" ]]; then            
            set_language "$tmp"
        else
            f_print_error "Nieznany kod jezyka [$1]"
            list_languages
            exit
        fi
        ;;
        
        # abbrev
        "-a" | "--abbrev")
        shift
        if [[ -z "$1" ]]; then
          f_print_error "Nie określono wstawki"
          exit
        fi
		
        g_Abbrev="$1"
        ;;
		
        # abbrev
        "--conv-abbrev")
        shift
        if [[ -z "$1" ]]; then
          f_print_error "Nie określono wstawki dla konwersji"
          exit
        fi
		
        g_ConvAbbrev="$1"
        ;;
		
        # script
        "-S" | "--script")
        shift
        if [[ -z "$1" ]]; then
          f_print_error "Nie określono wstawki"
          exit
        fi
        
		g_Script="$1"
        ;;
		
		
        # skip flag
        "--save-orig")
        g_DeleteIntermediate=false
        ;;
        
        # destination format definition
        "-f" | "--format")
        shift
        g_Format="$1"
        ;;
    
        # parameter is not a known argument, probably a filename
        *)
        g_Params=( "${g_Params[@]}" "$1" )
        ;;
        
    esac        
    shift
done

########################################################################
########################################################################
########################################################################

# parameters validation
if [[ -n "$g_Pass" ]] && [[ -z "$g_User" ]]; then
    f_print_error "Podano haslo, lecz nie podano loginu. Uzupelnij dane !!!"
    exit
fi

if [[ -z "$g_Pass" ]] && [[ -n "$g_User" ]]; then
    f_print_error "Podano login, lecz nie podano hasla, uzupelnij dane !!!"
    exit
fi

if [[ $g_SubotagePresence -eq 1 ]]; then    
    f_valid=0
    for i in "${g_Formats[@]}"; do      
        if [[ "$i" = "$g_Format" ]]; then
            f_valid=1
            break
        fi      
    done
    
    if [[ $f_valid -eq 0 ]] && [[ "$g_Format" != "no_conversion" ]]; then
        f_print_error "Podany format docelowy jest niepoprawny: [$g_Format] !!!"
        exit
    fi
fi

# be sure not to overwrite actual video file
if [[ ${#g_Params[*]} -eq 0 ]] && [[ "$g_LogFile" != "none" ]]; then
   f_print_error "Nie podales pliku loga !!!"
   exit   
elif [[ "$g_LogFile" != "none" ]]; then
   exec 3>&1 1> "$g_LogFile"
fi

# initialisation 2
f_check_mandatory_tools

########################################################################
########################################################################
########################################################################

echo "Wywolano o [$(date)]"
#set -- "${g_Params[@]}"
prepare_file_list "${g_Params[@]}"
download_subs

########################################################################
########################################################################
########################################################################

echo
echo "Podsumowanie"
echo -e "Pominieto:\t[$g_Skipped]"
echo -e "Pobrano:\t[$g_Downloaded]"
echo -e "Niedostepne:\t[$g_Unavailable]"
echo -e "Lacznie:\t[${#g_FileList[*]}]"
      
# restore original stdout
if [[ "$g_LogFile" != "none" ]]; then   
   exec 1>&3 3>&-
fi

# EOF
