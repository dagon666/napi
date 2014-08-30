#!/bin/bash

# napi project user/password configuration
# (may be left blank)
g_User=""
g_Pass=""

g_NapiPass="iBlm8NTigvru0Jr0"
g_Lang="PL"
g_VideoUris=( 'avi' 'rmvb' 'mov' 'mp4' 'mpg' 'mkv' 'mpeg' 'wmv' )

# if pynapi is not acceptable then use "other" - in this case p7zip is 
# required to finish processing
g_Revison="v1.1.2"
g_Version="pynapi"
#g_Version="other"

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

# global file list
g_FileList=( )
g_Okladka=""
g_Format="no_conversion"
g_Formats=( )
g_Params=( )

# subotage presence indicator
g_SubotagePresence=0

# fps detection tools: mediainfo mplayer
g_FpsTool=""
g_Fps=0
g_AvailableOne=0
g_LogFile="none"

########################################################################
########################################################################
########################################################################

function display_help
{
    echo "=============================================================="
    echo "napi.sh version $g_Revison (identifies as $g_Version)"
    echo "napi.sh [OPCJE] <plik|katalog|*>"
    echo "   -c | --cover - pobierz okladke"
    echo "   -u | --user <login> - uwierzytelnianie jako uzytkownik"
    echo "   -p | --pass <passwd> - haslo dla uzytkownika <login>"
    echo "   -l | --log <logfile> - drukuj output to pliku zamiast"
    echo "                          na konsole"
        
    if [[ $g_SubotagePresence -eq 1 ]]; then    
        echo "   -f | --format - konwertuj napisy do formatu (wym. subotage.sh)"                
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
		echo " napi.sh -f subrip *		 - sciaga napisy dla kazdego znalezionego pliku"
		echo "                           po czym konwertuje je do formatu subrip"
    
        if [[ $g_AvailableOne -eq 0 ]]; then 
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
# @brief: check if the given file is a video file
# @param: video filename
# @return: bool 1 - is video file, 0 - is not a video file
function check_extention
{
    is_video=0  
        filename=$(basename "$1")
        extention=$(echo "${filename##*.}" | tr [A-Z] [a-z])

    for ext in "${g_VideoUris[@]}"; do
        if [[ "$ext" == "$extention" ]]; then
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
function f
{
    t_idx=( 0xe 0x3 0x6 0x8 0x2 )
    t_mul=( 2 2 5 4 3 )
    t_add=( 0 0xd 0x10 0xb 0x5 )
    suma=$1
    b=""    

    for i in `seq 0 4`; do
        a=${t_add[$i]}
        m=${t_mul[$i]}
        g=${t_idx[$i]}
        
        t=$(( a + 16#${suma:$g:1}))
        v=$((16#${suma:$t:2} ))
        
        x=$(( (v*m) % 0x10 ))
        z=`printf "%X" $x`
        b="$b`echo $z | tr '[A-Z]' '[a-z]'`"
    done
    echo $b
}

#
# @brief: retrieve subtitles
# @param: md5sum
# @param: hash
# @param: outputfile
#
function get_subtitles
{   
    url="http://napiprojekt.pl/unit_napisy/dl.php?l=$g_Lang&f=$1&t=$2&v=$g_Version&kolejka=false&nick=$g_User&pass=$g_Pass&napios=posix"

    if [[ $g_Version = "other" ]]; then
        wget -q -O napisy.7z $url
        7z x -y -so -p$g_NapiPass napisy.7z 2> /dev/null > "$3"
        rm -rf napisy.7z
    
        if [[ -s "$3" ]]; then
            echo "1"
        else
            echo "0"
            rm -rf "$3"     
        fi
    else
        wget -q -O "$3" $url
        size=$(stat -c%s "$3")
    
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
function get_cover
{
    url="http://www.napiprojekt.pl/okladka_pobierz.php?id=$1&oceny=-1"
    wget -q -O "$2" $url
}

#
# @brief prepare a list of file which require processing
# @param space delimited file list string
#
function prepare_file_list
{
    echo "=================="
    echo "Tworzenie listy plikow..."
    echo "=================="
    echo
                
    for file in "$@"; do
        
        # sprawdz czy plik istnieje, jezeli nie, pomin go
        if [[ ! -s "$file" ]]; then
            echo "Podany plik nie istnieje lub jest pusty: [\"$file\"], pomijam"
            continue

        # sprawdz czy jest katalogiem   
        # jezeli tak to przeszukaj katalog
        elif [[ -d "$file" ]]; then
            echo "Przeszukuje zawartosc katalogu: [\"$file\"]..."
            
            unset templist i
            while IFS= read -r file2; do
            
                # check if the respective file is a video file (by extention)       
                if [[ $(check_extention "$file2") == 1 ]]; then
                    templist[i++]="$file2"
                fi
     
            done < <(find "$file" -type f)

            echo "Katalog zawiera ${#templist[*]} plikow"
            g_FileList=( "${g_FileList[@]}" "${templist[@]}" )
        else
            # check if the respective file is a video file (by extention)       
            if [[ $(check_extention "$file") == 1 ]]; then
                g_FileList=( "${g_FileList[@]}" "$file" )
            fi
        fi
    done
    echo "Lista gotowa."
}

#
# @ brief try to download subs for all the files present in the list
#
function download_subs
{   
    echo "=================="
    echo "Pobieram napisy..."
    echo "=================="
    echo
        
    for file in "${g_FileList[@]}"; do
        
        # input/output filename manipulation
        base=`basename "$file"`
        output_path=`dirname "$file"`
        output="$output_path/${base%.*}.txt"
        output_img="$output_path/${base%.*}.jpg"
        conv_output="$output_path/ORIG_${base%.*}.txt"
        
        if [[ -e "$output" ]] || [[ -e "$conv_output" ]]; then
            echo "Plik z napisami juz istnieje [$output]. Pomijam !!!"
            continue    
        else

            # md5sum and hash calculation
            suma=`dd if="$file" bs=1024k count=10 2> /dev/null | md5sum | cut -d ' ' -f 1`
            hash=$(f $suma)
        
            napiStatus=$(get_subtitles $suma $hash "$output")       
            if [[ $napiStatus = "1" ]]; then
                echo "Napisy pobrano pomyslnie [$base] !!!"
                
                # Potrzebna konwersja do innego formatu
                if [[ $g_SubotagePresence -eq 1 ]] && [[ $g_Format != "no_conversion" ]]; then
					echo "Konwertuje napisy do formatu: [$g_Format]"
					
					# okresl rozszerzenie wyjsciowe i plik wyjsciowy
					# jezeli rozszerzenie = txt to skopiuj oryginal z 
					# przedrostkiem ORIG_ a plik o nazwie filmu bedzie po konwersji
					case "$g_Format" in
					"subrip")
					outputSubs="$output_path/${base%.*}.srt"
					;;
					
					"subviewer")
					outputSubs="$output_path/${base%.*}.sub"
					;;
					
					*)
					cp $output "$conv_output"
					outputSubs="$output"
					output="$conv_output"
					;;
					esac
															
					subotage_c1="subotage.sh -i '$output' -of $g_Format -o '$outputSubs'"
					f_detect_fps "$file"
					if [[ "$g_Fps" != "0" ]]; then
						echo "FPS okreslony na podstawie pliku wideo: [$g_Fps]"
						subotage_c2="-fi $g_Fps"
					else
						echo "Nie udalo sie okreslic Fps. Okreslam na podstawie pliku napisow lub przyjmuje dom. wart."
						subotage_c2=""
					fi
					
					echo "Wolam subotage.sh"
					echo "=================="
					subotage_call="$subotage_c1 $subotage_c2"					
					eval $subotage_call
					echo "=================="
                fi
            else
                echo "Napisy niedostepne [$base]"
                continue
            fi
            
            if [[ $g_Okladka = "1" ]]; then
                get_cover $suma "$output_img"
            fi
        fi

    done    
}

#
# @brief get fps information directly from video file
# @param video file
#
function video_file_get_fps
{
    video_fps=$(mplayer -ao null -vo null -frames 0 -identify "$1" 2> /dev/null | grep ID_VIDEO_FPS)
    fps=$(echo $video_fps | cut -d '=' -f 2)
    echo $fps
}

#
# @brief check if subotage.sh is installed and available
#
function check_for_subotage
{
    if [[ -n $(builtin type -P subotage.sh) ]]; then
        g_SubotagePresence=1
    fi
}

#
# @brief check for FPS detection tools
#
function check_for_fps_detectors
{
    if [[ -n $(builtin type -P mediainfo) ]]; then
        g_FpsTool="mediainfo \"{}\" | grep -i 'frame rate' | tr -d '[\r a-zA-Z:]'"        
        g_AvailableOne=1
        return
    
    elif [[ -n $(builtin type -P mplayer) ]]; then    
        g_FpsTool="mplayer -identify -vo null -ao null -frames 0 \"{}\" 2> /dev/null | grep ID_VIDEO_FPS | cut -d '=' -f 2"
        g_AvailableOne=1
        return
                
    fi
}

# @brief error wrapper
function f_print_error
{
   if [[ "$g_LogFile" != "none" ]]; then   
      echo -e "$@"
   else
      echo -e "$@" > /dev/stderr
   fi
}

# @brief detect fps from video file
function f_detect_fps
{
   if [[ $g_AvailableOne -ne 0 ]]; then
		echo "Okreslam FPS na podstawie pliku video"
		cmd=${g_FpsTool/\{\}/"$1"}		
		tmpFps=$(eval $cmd)
		
		if [[ $(echo $tmpFps | sed -r 's/^[0-9]+[0-9.]*$/success/') = "success" ]]; then
			g_Fps=$tmpFps
		fi		
	else
		echo -e "Brak narzedzi do wykrywania FPS.\nFPS zostanie okreslony na podstawie pliku napisow, lub przyjmie sie wartosc domyslna."
	fi
}

########################################################################
########################################################################
########################################################################

# initialisation
check_for_subotage
check_for_fps_detectors

if [[ $g_SubotagePresence -eq 1 ]]; then
    g_Formats=( $(subotage.sh -gf) )
fi

# if no arguments are given, then print help and exit
if [[ $# -lt 1 ]] || [[ $1 == "--help" ]] || [[ $1 == "-h" ]]; then
    display_help
    exit
fi


# command line arguments parsing
while [ $# -gt 0 ]; do

    case "$1" in
        # pobieranie okladek
        "-c" | "--cover")
        g_Okladka=1
        ;;
        
        # nazwa uzytkownika
        "-u" | "--user")        
        shift
        if [[ -z "$1" ]]; then
            f_print_error "Nie podano nazwy uzytkownika"
            exit
        fi
        g_User="$1"
        ;;
        
        # haslo
        "-p" | "--pass")
        shift
                
        if [[ -z "$1" ]]; then
            f_print_error "Nie podano hasla dla uzytkownika [$g_User]"
            exit
        fi      
        g_Pass="$1"     
        ;;

        # logowanie do pliku
        "-l" | "--log")
        shift
        if [[ -z "$1" ]]; then
            f_print_error "Nie podano nazwy pliku dziennika"
            exit        
        fi
        g_LogFile="$1"           
        ;;

        # definicja formatu docelowego
        "-f" | "--format")
        shift
        g_Format="$1"
        ;;
    
        # Parametr nie jest argumentem, zapewne nazwa pliku
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
    
    if [[ $f_valid -eq 0 ]]; then
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

########################################################################
########################################################################
########################################################################

echo
echo "=================="
echo "Wywo³ano o [$(date)]"
echo "=================="
echo

#set -- "${g_Params[@]}"
prepare_file_list "${g_Params[@]}"
download_subs

########################################################################
########################################################################
########################################################################

echo
echo "=================="
echo "Koniec, przetworzono lacznie ${#g_FileList[*]} plikow"
echo "=================="
echo

       
# restore original stdout
if [[ "$g_LogFile" != "none" ]]; then   
   exec 1>&3 3>&-
fi

# EOF
