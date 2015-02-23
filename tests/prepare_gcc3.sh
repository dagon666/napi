#!/bin/bash

# force indendation settings
# vim: ts=4 shiftwidth=4 expandtab


########################################################################
########################################################################
########################################################################

#  Copyright (C) 2015 Tomasz Wisniewski aka 
#       DAGON <tomasz.wisni3wski@gmail.com>
#
#  http://github.com/dagon666
#  http://pcarduino.blogspot.co.ul
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


path_root=""

if [[ -z "$1" ]]; then
	echo "prepare_gcc3.sh <installation_root_path>"
	exit
fi
path_root="$1"

if [[ -e "${path_root}/gcc-3.0" ]]; then
	echo "GCC3 already installed. Nothing to do. Skipping"
	exit
fi

export LIBRARY_PATH=/usr/lib/$(gcc -print-multiarch)
export C_INCLUDE_PATH=/usr/include/$(gcc -print-multiarch)
export CPLUS_INCLUDE_PATH=/usr/include/$(gcc -print-multiarch)

cd /tmp

if ! [[ -e gcc-3.0.tar.bz2  ]]; then
	wget http://gcc.igor.onlinedirect.bg/old-releases/gcc-3/gcc-3.0.tar.bz2
fi

if ! [[ -e gcc-3.0 ]]; then
	tar jvxf gcc-3.0.tar.bz2
	cd gcc-3.0
	patch -p1 -i /vagrant/tests/0001-collect-open-issue.patch
	cd ..
fi

mkdir -p gcc-build
cd gcc-build

../gcc-3.0/configure --prefix="${path_root}/gcc-3.0" --enable-shared --enable-languages=c --disable-libgcj --disable-java-net --disable-static-libjava
make 2>&1 | tee compilation.log
sudo make install
rm -rf gcc-build
