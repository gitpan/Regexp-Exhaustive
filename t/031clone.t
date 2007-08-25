use Test::More tests => 2 + 3;
BEGIN { $^W = 1 }
use strict;

my $CLASS = 'Regexp::Exhaustive';

require_ok($CLASS);
use_ok($CLASS);

# Make sure that clone doesn't restart the match.

my $m = $CLASS->new('1234' => qr/./);

is($m->next, 1);
my $clone = $m->clone;
is($clone->next, 2);
is($m->next, 2);
