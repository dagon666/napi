*bashnapi* comes with it's own test suite and environment. It relies on a couple of dependencies

- vagrant
- shunit2
- virtualbox
- perl with Test::More and prove installed

The suite creates a dedicated virtual machine basing on a UBUNTU presice 12.04 32 bit box. It must be available in vagrant. 
In order to add execute:

	`$ vagrant box add hashicorp/precise32`

In order to prepare the environment and run the tests bring the vagrant box first:

    `$ vagrant up`

After this has been done use the *run_tests.sh* wrapper to start the environment preparations and execute the tests themselves. When run for the first time it will try to download and compile all the necessary packages - be prepared that it may take some time.

The test suite is divided in two. There is a set of unit tests under unit_napi.sh (only for napi.sh at the moment). The idea behind those is to verify the implementation of the given fragments of code (functions) and test them independently of the rest of the code. Unit tests are implemented with shuni2 framework.

The system tests are implemented as a Perl test scripts and they are doing the actual verification of the script. They are exercising various script options and retrieving real data from live napiprojekt servers.
