use Test::More tests => 2 + 4*2;
BEGIN { $^W = 1 }
use strict;

my $module = 'Regexp::Exhaustive';

require_ok($module);
use_ok($module, 'exhaustive');

{
    my $str = 'abcde';
    my $re = qr/(.)(.)(.)/;
    my $vars = sub { \@_ }->($1, $2);
    my $count  = exhaustive($str => qr/$re/, @$vars);
    my @result = exhaustive($str => qr/$re/, @$vars);
    my @facit = (
        [qw/ a b /],
        [qw/ b c /],
        [qw/ c d /],
    );
    is($count, @facit);
    is_deeply(\@result, \@facit);
}
{
    my $str = 'abcde';
    my $re = qr/(.)(.)/;
    my $vars = sub { \@_ }->($1);
    my $count  = exhaustive($str => qr/$re/, @$vars);
    my @result = exhaustive($str => qr/$re/, @$vars);
    my @facit = qw/ a b c d /;
    is($count, @facit);
    is_deeply(\@result, \@facit);
}
{
    my $str = 'abcde';
    my $re = qr/(.)(.)/;
    my $vars = sub { \@_ }->(\@-);
    my $count  = exhaustive($str => qr/$re/, @$vars);
    my @result = exhaustive($str => qr/$re/, @$vars);
    my @facit = (
        [ 0, 0, 1 ],
        [ 1, 1, 2 ],
        [ 2, 2, 3 ],
        [ 3, 3, 4 ],
    );
    is($count, @facit);
    is_deeply(\@result, \@facit);
}
{
    my $str = 'abcde';
    my $re = qr/(.)(.)/;
    my $vars = sub { \@_ }->($1, \@-);
    my $count  = exhaustive($str => qr/$re/, @$vars);
    my @result = exhaustive($str => qr/$re/, @$vars);
    my @facit = (
        [ 'a', [ 0, 0, 1 ] ],
        [ 'b', [ 1, 1, 2 ] ],
        [ 'c', [ 2, 2, 3 ] ],
        [ 'd', [ 3, 3, 4 ] ],
    );
    is($count, @facit);
    is_deeply(\@result, \@facit);
}
