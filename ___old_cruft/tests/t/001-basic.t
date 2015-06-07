#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

my $tmp;
my $shell = $ENV{NAPI_TEST_SHELL} // "/bin/bash";

use lib qw(./lib);
use NapiTest;

#>TESTSPEC
#
# Brief:
# 
# Check if napi.sh general invocation doesn't produce any shell errors
#
# Preconditions:
# - None
#
# Procedure:
# - Call the help option and listen for number of lines produces on the standard error
#
# Expected results:
# - The script shouldn't produce any error lines on STDERR
#
is ( $tmp = 
	 	(NapiTest::qx_napi($shell, "--help 2>&1 > /dev/null | wc -l") =~ s/\R//gr),
		0, 
		"General invocation" );

#>TESTSPEC
#
# Brief:
# 
# Check if subotage.sh general invocation doesn't produce any shell errors
#
# Preconditions:
# - None
#
# Procedure:
# - Call the help option and listen for number of lines produces on the standard error
#
# Expected results:
# - The script shouldn't produce any error lines on STDERR
#
is ( $tmp = 
		(NapiTest::qx_subotage($shell, "--help 2>&1 > /dev/null | wc -l") =~ s/\R//gr),
		0, 
		"Subotage General invocation" );

#>TESTSPEC
#
# Brief:
# 
# Check if napi.sh correctly detects the subotage.sh presence
#
# Preconditions:
# - napi.sh & subotage.sh must be available in public $PATH
#
# Procedure:
# - Call the help option in napi.sh and look for subotage specific help strings
#
# Expected results:
# - subotage specific help should be visible
#
is ( NapiTest::system_napi($shell, "--help | grep microdvd"), 0, "Subotage help" );


#>TESTSPEC
#
# Brief:
# 
# Check if subotage.sh produces correct help output
#
# Preconditions:
# - napi.sh & subotage.sh must be available in public $PATH
#
# Procedure:
# - Call the help option in subotage.sh
#
# Expected results:
# - subotage should list all the supported formats
#
is ( NapiTest::system_subotage($shell, "--help | grep microdvd"), 0, "Subotage help" );


#>TESTSPEC
#
# Brief:
# 
# Check if napi.sh correctly detects the iconv presence
#
# Preconditions:
# - napi.sh & subotage.sh must be available in public $PATH
# - iconv should be available in the system
#
# Procedure:
# - Call the help option in napi.sh and look for the presence of the iconv specific help
#
# Expected results:
# - the help output should contain iconv specific help
#
is ( NapiTest::system_napi($shell, "--help | grep iconv"), 0, "Iconv detection" );


#>TESTSPEC
#
# Brief:
# 
# Verify multiple language support help
#
# Preconditions:
# - None
#
# Procedure:
# - Call the -L option with list argument
#
# Expected results:
# - with list argument napi should produce a list of supported languages (that includes polish)
#
is ( NapiTest::system_napi($shell, "-L list 2>/dev/null | grep Polski"), 0, "Language selection" );


done_testing();
