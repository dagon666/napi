#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

my $tmp;

# general invocation tests
is ( $tmp = `/vagrant/napi.sh --help 2>&1 > /dev/null | wc -l` =~ s/\R//gr,
		0, 
		"General invocation" );

# subotage general invocation tests
is ( $tmp = `/vagrant/subotage.sh --help 2>&1 > /dev/null | wc -l` =~ s/\R//gr,
		0, 
		"Subotage General invocation" );

# subotage detection
is ( system("/vagrant/napi.sh --help | grep microdvd"), 0, "Subotage help" );

# subotage detection
is ( system("/vagrant/subotage.sh --help | grep microdvd"), 0, "Subotage help" );

# iconv detection
is ( system("/vagrant/napi.sh --help | grep iconv"), 0, "Iconv detection" );

# language support detection
is ( system("/vagrant/napi.sh -L | grep Polski"), 0, "Language selection" );


done_testing();
