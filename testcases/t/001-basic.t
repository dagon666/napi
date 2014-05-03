#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

# general invocation tests
is ( chomp `/vagrant/napi.sh --help > /dev/null | wc -l`,
		0, 
		"General invocation" );

is ( system("/vagrant/napi.sh --help | grep microdvd"), 0, "Subotage help" );


done_testing();
