#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(./lib);
use NapiTest;

use Test::More;
use File::Copy;

my $shell = $ENV{NAPI_TEST_SHELL} // "/bin/bash";

NapiTest::clean_testspace();
mkdir $NapiTest::testspace . "/converted";


#
# prepare the assets in the testspace
#
sub prepare_assets {
	system("cp -r " . 
		$NapiTest::assets . "/subtitles " .  $NapiTest::testspace);
}


#
# helper function
#
sub count_lines {
	my $cnt = 0;
	open my $fn, "<", $_[0];
	
	while (<$fn>) {
	}

	$cnt=$.;
	close $fn;
	return $cnt;
}


#
# all the supported formats
#
my @formats = (
	'subrip',
	'microdvd',
	'mpl2',
	'tmplayer',
	'subviewer2'
);


my @dst_formats=();
my $cnt = 0;

# prepare the goodies
prepare_assets;


#>TESTSPEC
#
# Brief:
# 
# Verify if the conversion from each supported format to any other is 
# performed correctly
#
# Preconditions:
# - subotage.sh must be available in public $PATH
# - prepare subtitles directory containing input files of every supported format
#
# Procedure:
# - Call subotage with given file and requested output format
# - check if the destination file exists
# - check if subotage return code doesn't indicate error
# - check the if the format detect by subotage indicates requested format
#
# Expected results:
# - the converted file should be in format as selected prior to conversion
#

# iterate through formats
foreach my $format (@formats) {

	# strip out current format from processing
	@dst_formats = map { $_ ne $format ? $_ : () } @formats;

	# and through files of given format
	foreach my $file (glob ($NapiTest::testspace . '/subtitles/*' . $format . '*')) {

		# and through destination formats
		foreach my $dst_format (@dst_formats) {

			my $dst_file = $NapiTest::testspace . 
				"/converted/out_${format}_${dst_format}_${cnt}.txt";
			
			my $rv = NapiTest::system_subotage($shell, " -i " . $file . 
				" -of $dst_format -o $dst_file ");

			my $minimum = 6;

			$minimum = 12 if $dst_format eq 'subviewer2';
			$minimum = 10 if $dst_format eq 'subrip';
			$minimum = 2 if $format eq 'subviewer2';

			is ($rv, 0, "return value for $format -> $dst_format conversion");
			is ( -e $dst_file, 1, "checking $dst_file existence" );
			ok ( (count_lines $dst_file) > $minimum, "the number of lines $dst_file" );

			# check format detection
			is ( (split ' ', qx/subotage.sh -gi -i $dst_file | grep IN_FORMAT/)[3],
				$dst_format,
				"checking if converted format is $dst_format"
			);

			$cnt++;
		}
	}
}


# NapiTest::clean_testspace();
done_testing();
