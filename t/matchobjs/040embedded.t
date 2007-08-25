#!/usr/bin/perl -w

use Test::More tests => 2 + 1;
BEGIN { $^W = 1 }
use strict;

my $module = 'Regexp::Exhaustive';
my $CLASS = 'Regexp::Exhaustive::_Match';

require_ok($module);
use_ok($module);

{
    my $str = 'abcdefgh';
    my $match;
    $str =~ /.*(?{$match = $CLASS->new($str)})/;

    is($match->match, $str);
}
