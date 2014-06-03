#!/bin/bash

path_root="/home/vagrant";

vagrant up

# prepare the environment
time vagrant ssh -c "/vagrant/tests/prepare_gcc3.sh $path_root"
time vagrant ssh -c "cd /vagrant/tests && ./prepare.pl $path_root"

# run unit tests
time vagrant ssh -c "cd /vagrant/tests && ./unit_napi.sh $path_root"

# run system tests
# time vagrant ssh -c "cd /vagrant/tests && prove"

