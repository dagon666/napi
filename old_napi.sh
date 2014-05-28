#!/bin/bash

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


# list of all mandatory to basic functionality tools
declare -a g_MandatoryTools=(  $g_Md5 'tr' 'printf' 
                    'wget' 'find' 'dd' 
                    'grep' 'sed' 'cut' 'seq' )

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

g_OrigPrefix="ORIG_"
g_OrigDelete=0

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
g_Converted=0

########################################################################
########################################################################
########################################################################

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

	local size=$(stat $g_StatParams "$2")
	[[ $size -eq 0 ]] && rm -rf "$2"
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
		
        # movie filename without path
        local base=$(basename "$file")
		   
        # movie path without filename
        local output_path=$(dirname "$file")
		
        # movie filename without extension
        local output_file_noext="${base%.*}"

        # jezeli ustawiona wstawka, to dodaje
        if [[ "$g_Abbrev" != "" ]]; then
            echo "Dodaje '$g_Abbrev' do rozszerzenia"
            output_file_noext="${output_file_noext}.${g_Abbrev}"
        fi

		# output filename for the subtitles file
        local output_file="$output_file_noext.$g_DefaultExt"
		
        # output path for the subtitles file
        local output="$output_path/$output_file"
		
        # if a conversion has been requested this is the original subtitles path
        local conv_output="$output_path/${g_OrigPrefix}$output_file"

		# path after conversion
		local final_output="$output"
		
        # output image filename
        local output_img="$output_path/${base%.*}.jpg"
		
        # this flag is set to 1 if the subtitles already exist
        local fExists=0
        
        # determine the output extention and the output filename
        # if ext == $g_DefaultExt then copy the original with a ORIG_ prefix
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
		
        # set the exists flag if the original or to be converted already exists
        if [[ -e "$final_output" ]]; then
            fExists=1
        fi

        # skip if requested and already exists
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
					# path for the converted subtitles file
                    local outputSubs=""
                    local subotage_c2=""

                    echo " -- Konwertuje napisy do formatu: [$g_Format]"
                
                    # if delete orig flag has been requested don't rename the original file
                    if [[ $g_OrigDelete -eq 0 ]]; then
                        # copy not converted file (the original one to ORIG_)
                        cp "$output" "$conv_output"
                    fi

					if [[ "$output" == "$final_output" ]]; then
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
                    local subotage_code=$?

                    # remove the old format if conversion was successful
					if [[ $subotage_code -eq 0 ]]; then
                    	[[ "$output" != "$outputSubs" ]] && rm -f "$output"
                        output="$outputSubs"
						g_Converted=$(( $g_Converted + 1 ))
					fi

                fi # [[ $g_SubotagePresence -eq 1 ]] && [[ $g_Format != "no_conversion" ]]

                # charset conversion
                if [[ $g_IconvPresence -eq 1 ]] && [[ $g_Charset != "" ]]; then
                    echo " -- Konwertuje kodowanie"
                    local tmp=`mktemp -t napi.XXXXXXXXXX`
                    iconv -f WINDOWS-1250 -t $g_Charset "$output" > $tmp
                    mv $tmp "$output"
                fi # [[ $g_IconvPresence -eq 1 ]] && [[ $g_Charset != "" ]]

                # execute external script 
				if [[ $g_Script != "" ]]; then
					echo " -- Wolam: $g_Script \"$output\""
					$g_Script "$output"
				fi

            else # [[ $napiStatus = "1" ]]
                    echo -e "[UNAV]\t[$base]:\tNapisy niedostepne !!!"
                    g_Unavailable=$(( $g_Unavailable + 1 ))
                    continue
            fi # [[ $napiStatus = "1" ]]
                
            # download cover if requested
            if [[ $g_Cover = "1" ]]; then
                get_cover "$sum" "$output_img"
            fi

        fi # [[ $fExists -eq 1 ]] && [[ $g_Skip -eq 1 ]]
    done    
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
          f_print_error "Nie określono sciezki do skryptu"
          exit
        fi
        
		g_Script="$1"
        ;;
		
		
        # orig prefix 
        "-d" | "--delete-orig")
        g_OrigDelete=1
        ;;

        # orig prefix 
        "-o" | "--orig-prefix")
        shift
        g_OrigPrefix="$1"
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
if [[ $g_SubotagePresence -eq 1 ]]; then    
	echo -e "Przekonw.:\t[$g_Converted]"
fi
echo -e "Niedostepne:\t[$g_Unavailable]"
echo -e "Lacznie:\t[${#g_FileList[*]}]"
      
# restore original stdout
if [[ "$g_LogFile" != "none" ]]; then   
   exec 1>&3 3>&-
fi

# EOF
