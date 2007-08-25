use Test::More tests => 2 + 4 + 7;
BEGIN { $^W = 1 }
use strict;

my $CLASS = 'Regexp::Exhaustive';

require_ok($CLASS);
use_ok($CLASS);

# Make sure that pos() stays unchanged.
{
    my $str = '123456789';
    my $p = 7;

    pos($str) = $p;

    is(pos($str), $p);

    {
        my $m = $CLASS->new($str => qr/(.*?)/);
        is(pos($str), $p);

        $m->next;
        is(pos($str), $p);
    }

    is(pos($str), $p);
}

# Make sure that global matches don't effect the object.
{
    my $str = '123456789';
    my $p = 3;

    $str =~ /./g for 1 .. $p;

    is(pos($str), $p);

    {
        my $m = $CLASS->new($str => qr/(.+?)/);
        is(pos($str), $p);

        is(scalar $m->next, '1');
        is(scalar $m->next, '12');

        $str =~ /./g;
        is(pos($str), $p+1);

        is(scalar $m->next, '123');
    }

    is(pos($str), $p+1);
}
