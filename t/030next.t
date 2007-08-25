use Test::More tests => 2 + 1;
BEGIN { $^W = 1 }
use strict;

my $CLASS = 'Regexp::Exhaustive';

require_ok($CLASS);
use_ok($CLASS);

my $m = $CLASS->new("foo\nbar\nbaz" => qr/^.+?$/ms);
my @result;
while (my ($match) = $m->next) {
    $match =~ s/\n/\\n/g;
    push @result, $match;
}
my @facit = qw[
    foo
    foo\nbar
    foo\nbar\nbaz
    bar
    bar\nbaz
    baz
];
is("@result", "@facit");
