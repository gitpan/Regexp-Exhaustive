#!/usr/bin/perl -w

use Test::More tests => 2 + (2*(3 + 2) + 1 + 4 + 2*2*2) + 1;
BEGIN { $^W = 1 }
use strict;

my $CLASS = 'Regexp::Exhaustive';

require_ok($CLASS);
use_ok($CLASS);

{
    my $str = 'abcdefgh';
    my $re = qr/c(d)(e)f|(x)/;

    $str =~ /$re/;

    my @vars = (
        [qw/ $& $MATCH /] => $&,
        [qw/ $` $PREMATCH /] => $`,
        [qw/ $' $POSTMATCH /] => $',

        [qw/ $+ $LAST_PAREN_MATCH /] => $+,
        [qw/ $^R $LAST_REGEXP_CODE_RESULT /] => $^R,

        [qw/ $^N /] => $^N,

        [qw/ $1 /] => $1,
        [qw/ $2 /] => $2,
        [qw/ $3 /] => $3,
        [qw/ $4 /] => $4,

        [qw/ @+ @LAST_MATCH_END /] => [ @+ ],
        [qw/ @- @LAST_MATCH_START /] => [ @- ],
    );

    my $match = $CLASS->new($str => qr/$re/)->next;

    while (@vars) {
        my $names = shift @vars;
        my $value = shift @vars;

        for my $name (@$names) {
            if ($name =~ /^\$/) {
                is($match->var($name), $value, $name);
            }
            elsif ($name =~ /^\@/) {
                is($match->var($name), @$value, "$name (scalar)");
                is_deeply([ $match->var($name) ], $value, "$name (list)");
            }
            else {
                die "Test script error!";
            }
        }
    }
}

{
    my $str = 'abcdefgh';
    my $match = $CLASS->new($str => qr/a(?:(x))?(b)/)->next;

    my @errors;

    eval {
        local $SIG{__DIE__} = sub { push @errors, @_ };
        $match->var('foo');
    };

    like($@, qr/\Q$CLASS\E(?:::[^:]+)*: No such variable "foo" /, 'diagnostics');
}
