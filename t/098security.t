use Test::More tests => 2 + 2 + 2;
BEGIN { $^W = 1 }
use strict;

my $CLASS = 'Regexp::Exhaustive';

require_ok($CLASS);
use_ok($CLASS);

{
    package Regexp::Fake;
    our @ISA = 'Regexp';

    sub new { bless \ do { my $o = $_[1] } => $_[0] }

    use overload
        '""' => sub { ${$_[0]} },
        fallback => 1,
    ;
}
{
    my $str = 'abc';
    my $pat = '.';

    my $fake = Regexp::Fake::->new($pat);
    is("$fake", $pat);

    my $m = $CLASS->new($str => $fake);
    is($m->next, 'a');
}
{
    my $str = 'abc';

    my $fake = Regexp::Fake::->new('(?{1})');
    is("$fake", '(?{1})');

    my $msg = "Eval-group not allowed at runtime";
    eval { $CLASS->new($str => $fake) };
    like($@, qr/\Q$msg/, $msg);
}
