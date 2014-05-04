#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(./lib);
use NapiTest;

use Test::More;
use File::Copy;

NapiTest::clean_testspace();
NapiTest::prepare_fs();

# check with a single files
my @files = (
		{ 
			src => 'av1.dat',
			dst  => 'available.avi',
			res => 'available.txt',
			pattern => 'OK',
		},

		{ 
			src => 'unav1.dat',
			dst => 'unavailable.avi',
			res => 0,
			pattern => 'UNAV',
	   	},
);


# perform simple single file tests
foreach (@files) {
	copy $NapiTest::assets . '/' . $_->{src},
		 $NapiTest::testspace . '/' . $_->{dst};

	my $filename = $NapiTest::testspace . '/' . $_->{dst};
	my $subs = $NapiTest::testspace . '/' . $_->{res};

	like ( `/vagrant/napi.sh $filename`,
			qr/\[$_->{pattern}\]/,
			"Single File ($_->{dst}) test");

	is (-e $subs ? 1 : 0, 
			$_->{res} ? 1 : 0, 
			"Subtitles file ($_->{res}) presence test");

	unlink $NapiTest::testspace . '/' . $_->{dst};
	unlink $NapiTest::testspace . '/' . $_->{res} if $_->{res};
}




# NapiTest::clean_testspace();
done_testing();
