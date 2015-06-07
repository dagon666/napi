#!/usr/bin/env perl

########################################################################
########################################################################
########################################################################

#  Copyright (C) 2015 Tomasz Wisniewski aka 
#       DAGON <tomasz.wisni3wski@gmail.com>
#
#  http://github.com/dagon666
#  http://pcarduino.blogspot.co.ul
# 
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

########################################################################
########################################################################
########################################################################

package NapiTest;

use strict;
use warnings;
$|++;
use 5.010;

use Exporter ();
use LWP::Simple;
use Archive::Extract;
use Carp;
use File::Path qw/remove_tree/;


our $path_root = "/home/vagrant";
our $testspace = $path_root . '/testspace';
our $assets = $path_root . '/napi_test_files';
our $install_path = $path_root . '/napi_bin';


sub prepare_fs {

	my @dirs = (
			'movies',
			'mixed',
			'unavailable',
			'dir with white chars',
			'dir with "quotation" marks',
			'dir with \'quotation\' marks',
			'dir_with_subdirs',
			'special@[chars]-in.the.$$$.dir&#(name)-<%>'
	);

	foreach (@dirs) {
		mkdir $testspace . '/' . "$_";
	}
}


sub clean_testspace {
	print "Cleaning testspace\n";
	remove_tree glob $testspace . "/*";
}


sub parse_summary {
	my @strings = qw/
		OK
		UNAV
		SKIP
	   	CONV
	   	COVER_OK
	   	COVER_UNAV
		COVER_SKIP
		NFO_OK
		NFO_UNAV
		NFO_SKIP
	   	TOTAL
		/;

	my %output = ();
	my $input = shift // '';

	($output{lc $_}) = ($input =~ m/#\d+:\d+\s*$_\s->\s(\d+)/g) foreach (@strings);
	return %output;	
}


sub qx_tool {
	my $shell = shift // '/bin/bash';
	my $tool = shift // 'napi.sh';
	my $arguments = shift // '';
	return `$shell $install_path/$tool $arguments`;
}


sub system_tool {
	my $shell = shift // '/bin/bash';
	my $tool = shift // 'napi.sh';
	my $arguments = shift // '';
	return system("$shell $install_path/$tool $arguments") >> 8;
}


sub qx_napi {
	return qx_tool(shift, 'napi.sh', shift);
}


sub qx_subotage {
	return qx_tool(shift, 'subotage.sh', shift);
}


sub system_napi {
	return system_tool(shift, 'napi.sh', shift);
}


sub system_subotage {
	return system_tool(shift, 'subotage.sh', shift);
}


1;
