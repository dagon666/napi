#!/bin/bash

path_root="/home/vagrant";

vagrant up

# prepare the environment
time vagrant ssh -c "/vagrant/tests/prepare_gcc3.sh $path_root"
time vagrant ssh -c "cd /vagrant/tests && ./prepare.pl $path_root"

# run unit tests
vagrant ssh -c "cd /vagrant/tests && ./unit_napi.sh $path_root"
uni_status=$?

if [ $uni_status -ne 0 ]; then
	echo '==========================================='
	echo 'UNIT TESTY NIE POMYSLNE !!!'
	echo 'SYSTEM TESTY NIE ZOSTANA PRZEPROWADZONE !!!'
	echo '==========================================='
	exit -1
fi

# run system tests
time vagrant ssh -c "cd /vagrant/tests && prove"
sys_status=$?

if [ $uni_status -eq 0 ] && [ $sys_status -eq 0 ]; then
	echo '==========================================='
	echo 'TESTY ZAKONCZONE POMYSLNIE'
	echo '==========================================='
fi

# hibernate the VM
vagrant suspend
