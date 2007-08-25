use Test::More tests => 2 + 2;
BEGIN { $^W = 1 }
use strict;

my $CLASS = 'Regexp::Exhaustive';

require_ok($CLASS);
use_ok($CLASS);

# Make sure that clone doesn't restart the match.

my $str = '1234';

my $m = $CLASS->new("$str" => qr/./);

is($m->next, 1);

$str = 'abcd';

is($m->next, 2);
