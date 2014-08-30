#!/bin/bash

# napi project user/password configuration
# (may be left blank)
g_User=""
g_Pass=""

g_NapiPass="iBlm8NTigvru0Jr0"
g_Lang="PL"

# if pynapi is not acceptable then use "other" - in this case p7zip is 
# required to finish processing
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

function display_help
{
	echo "============================"
	echo "napi.sh version v0.2.1"
	echo "napi.sh [-c] <plik|katalog|*>"
	echo "   -c     - pobierz okladke"
	echo "============================"
	echo
	echo "Podaj Nazwe plik(u|ow)/katalog(u|ow), jako argument !!!"
	echo
	echo "Przyklady:"
	echo "    napi.sh film.avi"
	echo "    napi.sh -c film.avi"
	echo "    napi.sh *"
	echo "    napi.sh *.avi"
	echo "    napi.sh katalog_z_filmami"
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

########################################################################

if [[ ! -z $1 ]]; then
	g_Okladka=""
	if [[ $1 = "-c" ]]; then
		g_Okladka="1"
		shift
	fi	
fi

if [ $# -lt 1 ] || [ $1 == "--help" ]; then
	display_help
	exit
fi

# global file list
g_FileList=( )

echo "Tworzenie listy plikow..."
echo "========================="
for file in "$@"; do
	
	# sprawdz czy plik istnieje, jezeli nie, pomin go
	if [ ! -s "$file" ]; then
		echo "Podany plik nie istnieje lub jest pusty: [\"$file\"], pomijam"
		continue

	# sprawdz czy jest katalogiem	
	# jezeli tak to przeszukaj katalog
	elif [ -d "$file" ]; then
		echo "Przeszukuje zawartosc katalogu: [\"$file\"]..."
		
		unset templist i
		while IFS= read -r file2; do
		  templist[i++]="$file2"       
		done < <(find "$file" -type f)

		echo "Katalog zawiera ${#templist[*]} plikow"
		g_FileList=( "${g_FileList[@]}" "${templist[@]}" )
	else
		g_FileList=( "${g_FileList[@]}" "$file" )
	fi
done



echo "Lista gotowa, pobieram napisy..."
echo "================================"

for file in "${g_FileList[@]}"; do

	# md5sum and hash calculation
	suma=`dd if="$file" bs=1024k count=10 2> /dev/null | md5sum | cut -d ' ' -f 1`
	hash=$(f $suma)
	
	# input/output filename manipulation
	base=`basename "$file"`
	output_path=`dirname "$file"`
	output="$output_path/${base%.*}.txt"
	output_img="$output_path/${base%.*}.jpg"
	
	napiStatus=$(get_subtitles $suma $hash "$output")		
	if [[ $napiStatus = "1" ]]; then
		echo "Napisy pobrano pomyslnie [$base] !!!"
	else
		echo "Napisy niedostepne [$base]"
		continue
	fi
	
	if [[ $g_Okladka = "1" ]]; then
		get_cover $suma "$output_img"
	fi
done

echo "==================================================="
echo "Koniec, przetworzono lacznie ${#g_FileList[*]} plikow"

# EOF
