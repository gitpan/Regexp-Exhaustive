#!/usr/bin/perl -w

use Test::More tests => 2 + 9-1 + 3 + 2;
BEGIN { $^W = 1 }
use strict;

my $CLASS = 'Regexp::Exhaustive';

require_ok($CLASS);
use_ok($CLASS);

{
    my $str = 'abcdefgh';
    my $re = qr/c(d)(e)f/;
    my $match = $CLASS->new($str => qr/$re/)->next;

    $str =~ /$re/g;
    my %facit = (
        q{prematch} => $`,
        q{match} => $&,
        q{postmatch} => $',
        q{$1} => $1,
        q{$2} => $2,
        pos => pos($str),
    );

    $str =~ /a/;

    is($match->prematch, $facit{prematch}, 'prematch');
    is($match->match, $facit{match}, 'match');
    #is($match->match, $match, 'overload'); # overloading
    is($match->postmatch, $facit{postmatch}, 'postmatch');
    is($match->group(1), $facit{'$1'}, 'group');
    is($match->group(2), $facit{'$2'}, 'group');
    is($match->groups, 2, 'scalar groups');
    is_deeply([ $match->groups ], [qw/ d e /], 'list groups');
    is($match->pos, $facit{pos}, 'pos');
}
{
    my $str = 'abcdefgh';
    my $re = qr/a(?:(x))?(b)/;
    my $match = $CLASS->new($str => qr/$re/)->next;

    my $old_sig = $SIG{__WARN__} || sub { return };
    local $SIG{__WARN__} = sub {
        for (@_) {
            ok(0, "This shouldn't happen: $_");
        }
        goto &$old_sig;
    };

    is($match->group(1), undef);
    is($match->group(2), 'b');
    is($match->group(3), undef);
}
{
    my $str = 'abcdefgh';
    my $re = qr/../;
    my $match = $CLASS->new($str => qr/$re/)->next;

    is($match->pos, 2);
    $str =~ /a/;
    is($match->pos, 2);
}
