use Test::More tests => 2 + 3+6;
BEGIN { $^W = 1 }
use strict;

my $CLASS = 'Regexp::Exhaustive';

require_ok($CLASS);
use_ok($CLASS);

ok($CLASS->can('new'));
ok($CLASS->can('clone'));
ok($CLASS->can('next'));

my $MATCHCLASS = "$CLASS\::_Match";
ok($MATCHCLASS->can('new'));
ok($MATCHCLASS->can('prematch'));
ok($MATCHCLASS->can('match'));
ok($MATCHCLASS->can('postmatch'));
ok($MATCHCLASS->can('group'));
ok($MATCHCLASS->can('groups'));
