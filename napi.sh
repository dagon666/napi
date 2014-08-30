#!/bin/bash

# napi project user/password configuration
# (maybe left blank)
user=""
pass=""

###############################################################################
###############################################################################
## author: Tomasz Wisniewski aka DAGON
## http://www.dagon.bblog.pl
## http://hekate.homeip.net
##
## Maybe freely distributed and modified as long as 
## the author name is mentioned
##
## napi.sh v0.1.0
##
###############################################################################
###############################################################################

function display_help
{
	echo "napi.sh version v0.1.4"
	echo "napi.sh <plik|*>"
	echo "Podaj Nazwe pliku jako argument !!!"
	echo
	echo "Przyklady:"
	echo "    napi.sh film.avi"
	echo "    napi.sh *"
	echo "    napi.sh *.avi"
}

# mysterious f() function
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

if [ $# -lt 1 ]; then
	display_help
	exit
fi

for file in "$@"; do
	
	# sprawdz czy plik istnieje, jezeli nie, pomin go
	if [ ! -s "$file" ]; then
		echo "Podany plik nie istnieje lub jest pusty: [$file], pomijam"
		continue
	fi

	# sprawdz czy jest katalogiem	
	if [ -d "$file" ]; then
		echo "Podany plik jest katalogiem: [$file], pomijam"
		continue
	fi

	suma=`dd if="$file" bs=1024k count=10 2> /dev/null | md5sum | cut -d ' ' -f 1`
	base=`basename "$file"`
	output="${base%.*}.txt"
	hash=`f $suma`
	str="http://napiprojekt.pl/unit_napisy/dl.php?l=PL&f=$suma&t=$hash&v=other&kolejka=false&nick=$user&pass=$pass&napios=posix"
	
	wget -q -O napisy.7z $str
	7z x -y -so -piBlm8NTigvru0Jr0 napisy.7z 2> /dev/null > "$output"
	rm -rf napisy.7z
	
	if [[ -s "$output" ]]; then
		echo "Napisy pobrano pomyslnie [$file] !!!"
	else
		echo "Napisy niedostepne [$file]"
		rm -rf "$output"
		continue
	fi	
done
# EOF
