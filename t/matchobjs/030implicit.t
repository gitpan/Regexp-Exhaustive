#!/usr/bin/perl -w

use Test::More tests => 2 + 4;
BEGIN { $^W = 1 }
use strict;

my $CLASS = 'Regexp::Exhaustive';

require_ok($CLASS);
use_ok($CLASS);

{
    my $str = 'abcdefgh';
    my $re = qr/c(d)(e)f/;
    my $match = $CLASS->new($str => qr/$re/)->next;

    $str =~ /$re/;
    is_deeply($match->{'@-'}, \@-, '@-');
    is_deeply($match->{'@+'}, \@+, '@+');

    isnt($match->{'@-'}, \@-, '@-');
    isnt($match->{'@+'}, \@+, '@+');
}
