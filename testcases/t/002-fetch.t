#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(./lib);
use NapiTest;

use Test::More;
use File::Copy;

NapiTest::clean_testspace();
NapiTest::prepare_fs();

my $shell = $ENV{NAPI_TEST_SHELL} // "/bin/bash";


sub prepare_assets {
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
}


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

	like ( scalar NapiTest::qx_napi($shell, $filename),
			qr/\[$_->{pattern}\]/,
			"Single File ($_->{dst}) test");

	is (-e $subs ? 1 : 0, 
			$_->{res} ? 1 : 0, 
			"Subtitles file ($_->{res}) presence test");

	unlink $NapiTest::testspace . '/' . $_->{dst};
	unlink $NapiTest::testspace . '/' . $_->{res} if $_->{res};
}

prepare_assets();

my %output = ();
my $output = NapiTest::qx_napi($shell, $NapiTest::testspace);

%output = NapiTest::parse_summary($output);
is ($output{pobrano}, 21, "Total number downloaded");
is ($output{niedostepne}, 3, "Total number of unavailable");
is ($output{pobrano} + $output{niedostepne}, $output{lacznie}, "Total processed");

$output = NapiTest::qx_napi($shell, "-s " . $NapiTest::testspace);
%output = NapiTest::parse_summary($output);
is ($output{pominieto}, 21, "Total number of skipped");
is ($output{pominieto} + $output{niedostepne}, $output{lacznie}, "Total processed (with skipping)");


NapiTest::clean_testspace();
prepare_assets();

# prepare big files
my $dir_cnt = 0;
foreach my $dir (glob ($NapiTest::testspace . '/*')) {
	system("dd if=/dev/urandom of=" . $dir . "/test_file" . $_ . ".avi bs=1M count=" . $_)
		foreach(15, 20);
	$dir_cnt++;
}

$output = NapiTest::qx_napi($shell, "-b 12" . $NapiTest::testspace);
%output = NapiTest::parse_summary($output);
is ($output{niedostepne}, $dir_cnt * 2, "Number of processed files bigger than given size");

$output = NapiTest::qx_napi($shell, "-b 16" . $NapiTest::testspace);
%output = NapiTest::parse_summary($output);
is ($output{niedostepne}, $dir_cnt, "Number of processed files bigger than given size 2");


$output = NapiTest::qx_napi($shell, "-b 4" . $NapiTest::testspace);
%output = NapiTest::parse_summary($output);
is ($output{lacznie},
	$output{niedostepne} + $output{pobrano}, 
	"Number of processed files bigger than given size 2");


done_testing();
