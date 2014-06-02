#!/bin/bash

path_root="/home/vagrant";

vagrant up

# prepare the environment
time vagrant ssh -c "/vagrant/testcases/prepare_gcc3.sh $path_root"
time vagrant ssh -c "cd /vagrant/testcases && ./prepare.pl $path_root"

# run the tests
time vagrant ssh -c "cd /vagrant/testcases && prove"

