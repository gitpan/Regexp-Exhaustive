#!/usr/bin/perl -w

use Test::More tests => 2 + 1;
BEGIN { $^W = 1 }
use strict;

my $module = 'Regexp::Exhaustive';
my $CLASS = 'Regexp::Exhaustive::_Match';

require_ok($module);
use_ok($module);

my @methods = qw/
    new

    prematch
    match
    postmatch
    group
    groups

    var
/;

can_ok($CLASS, @methods);
