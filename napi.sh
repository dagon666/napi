#!/bin/sh

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

if [ -z "$1" ]; then
	echo "Podaj nazwe pliku z filmem"
	exit
fi

if [ ! -s "$1" ]; then
	echo "Podany plik nie istnieje: $1"
	exit
fi

suma=`dd if="$1" bs=1024k count=10 2> /dev/null | md5sum | cut -d ' ' -f 1`
base=`basename "$1"`
output="${base%.*}.txt"

echo $output

t_idx=( 0xe 0x3 0x6 0x8 0x2 )
t_mul=( 2 2 5 4 3 )
t_add=( 0 0xd 0x10 0xb 0x5 )


# mysterious f() function
function f
{
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

hash=`f`
str="http://napiprojekt.pl/unit_napisy/dl.php?l=PL&f=$suma&t=$hash&v=other&kolejka=false&nick=&pass=&napios=posix"

wget -O napisy.7z $str




7z x -y -so -piBlm8NTigvru0Jr0 napisy.7z 2> /dev/null > $output
rm -rf napisy.7z

if [[ -s $output ]]; then
	echo "Napisy pobrano pomyslnie !!!"
else
	echo "Napisy niedostepne"
	rm -rf $output
	exit
fi


