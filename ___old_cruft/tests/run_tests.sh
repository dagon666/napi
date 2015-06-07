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


path_root="/home/vagrant";

vagrant up

# prepare the environment
time vagrant ssh -c "/vagrant/tests/prepare_gcc3.sh $path_root"
time vagrant ssh -c "cd /vagrant/tests && ./prepare.pl $path_root"

declare -a tests=( 'unit' 'system' )
[ $# -ge 1 ] && tests=( "$@" )
executed=0


unit_tests() {
    # run unit tests
    declare -a utests=( 'unit_libnapi_common.sh' \
        'unit_napi.sh' \
        'unit_subotage_awk.sh' \
        'unit_subotage_gawk.sh' \
        'unit_subotage_mawk.sh' \
        )

    for s in "${utests[@]}"; do

        echo '==========================================='
        echo "$s"
        echo '==========================================='

        vagrant ssh -c "cd /vagrant/tests && ./$s $path_root"
        local uni_status=$?

        if [ $uni_status -ne 0 ]; then
            echo "==========================================="
            echo "$s - UNIT TESTY NIE POMYSLNE !!!"
            echo "SYSTEM TESTY NIE ZOSTANA PRZEPROWADZONE !!!"
            echo "==========================================="
            exit -1
        fi
    done
}


system_tests() {
    # run system tests with the following shells
    declare -a shells=( 'bash-2.04' \
        'bash-2.05' \
        'bash-2.05a' \
        'bash-2.05b' \
        'bash-3.0' \
        'bash-3.1' \
        'bash-3.2' \
        'bash-3.2.48' \
        'bash-4.0' \
        'bash-4.1' \
        'bash-4.2' \
        'bash-4.3' )

    for s in "${shells[@]}"; do
        echo '==========================================='
        echo "TESTUJE Z SHELLEM ($s)"
        echo '==========================================='

        vagrant ssh -c "cd /vagrant/tests && NAPI_TEST_SHELL=$path_root/shells_bin/$s prove"
        sys_status=$?

        if [ $sys_status -ne 0 ]; then
            echo '==========================================='
            echo "SYSTEM TESTY NIEPOMYSLNE Z SHELLEM ($s)"
            echo '==========================================='
            exit -1
        fi
    done
}


# execute the requests
for t in "${tests[@]}"; do
    fn="${t}_tests"
    $fn
    executed=$(( executed + 1 ))
done


if [ $executed -gt 0 ]; then
    echo '==========================================='
    echo 'WSZYSTKIE TESTY ZAKONCZONE POMYSLNIE'
    echo '==========================================='
fi

# hibernate the VM
vagrant suspend
