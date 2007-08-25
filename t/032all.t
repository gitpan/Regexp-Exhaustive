use Test::More tests => 2 + 2 + 2;
BEGIN { $^W = 1 }
use strict;

my $CLASS = 'Regexp::Exhaustive';

require_ok($CLASS);
use_ok($CLASS);

{
    my $m = $CLASS->new("foo\nbar\nbaz" => qr/^.+?$/ms);
    my @result = $m->all;
    my @facit = (
        "foo",
        "foo\nbar",
        "foo\nbar\nbaz",
        "bar",
        "bar\nbaz",
        "baz",
    );
    is("@result", "@facit");
}
{
    # This may fail and the documentation will still be valid,
    # but it's preferable if this succeeds.
    my $m = $CLASS->new('abc' => qr/./);
    is($m->next, 'a');
    is_deeply([ $m->all ], [qw/ a b c /]);
    is($m->next, 'b');
}
