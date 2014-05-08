#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

my $tmp;
my $shell = $ENV{NAPI_TEST_SHELL} // "/bin/bash";

use lib qw(./lib);
use NapiTest;

# general invocation tests
is ( $tmp = 
	 	(NapiTest::qx_napi($shell, "--help 2>&1 > /dev/null | wc -l") =~ s/\R//gr),
		0, 
		"General invocation" );

# subotage general invocation tests
is ( $tmp = 
		(NapiTest::qx_subotage($shell, "--help 2>&1 > /dev/null | wc -l") =~ s/\R//gr),
		0, 
		"Subotage General invocation" );

# subotage detection
is ( NapiTest::system_napi($shell, "--help | grep microdvd"), 0, "Subotage help" );

# subotage detection
is ( NapiTest::system_subotage($shell, "--help | grep microdvd"), 0, "Subotage help" );

# iconv detection
is ( NapiTest::system_napi($shell, "--help | grep iconv"), 0, "Iconv detection" );

# language support detection
is ( NapiTest::system_napi($shell, "-L 2>/dev/null | grep Polski"), 0, "Language selection" );


done_testing();
