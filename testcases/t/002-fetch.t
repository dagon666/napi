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


foreach my $dir (glob ($NapiTest::testspace . '/*')) {
	
	unless ($dir =~ /unavailable/ ) {
		copy $NapiTest::assets . "/av$_.dat", $dir . "/vid$_.avi"
			foreach(1..3);
	}
	else {
		copy $NapiTest::assets . "/unav1.dat", $dir . "/vid$_.avi"
			foreach(1..3);
	}
}

my $output = `/vagrant/napi.sh $NapiTest::testspace`;
my ($av) = ($output =~ m/Pobrano:\s+\[(\d+)\]/);
my ($unav) = ($output =~ m/Niedostepne:\s+\[(\d+)\]/);
my ($total) = ($output =~ m/Lacznie:\s+\[(\d+)\]/);

is ($av, 21, "Total number downloaded");
is ($unav, 3, "Total number of unavailable");
is ($av + $unav, $total, "Total processed");

$output = `/vagrant/napi.sh -s $NapiTest::testspace`;
my ($skipped) = ($output =~ m/Pominieto:\s+\[(\d+)\]/);
($total) = ($output =~ m/Lacznie:\s+\[(\d+)\]/);
($unav) = ($output =~ m/Niedostepne:\s+\[(\d+)\]/);

is ($skipped, 21, "Total number of skipped");
is ($skipped + $unav, $total, "Total processed (with skipping)");

NapiTest::clean_testspace();
done_testing();
