#!/usr/bin/env perl

use strict;
use warnings;
$|++;

use lib qw(./lib/);
use NapiTest qw/:all/;

print "Preparing shells\n";

$NapiTest::path_root = shift || '/home/vagrant';

NapiTest::prepare_env();
NapiTest::prepare_shells();
NapiTest::prepare_assets();
