package Regexp::Exhaustive;
use 5.006001;

$VERSION = 0.02;

use base 'Exporter';
@EXPORT_OK = qw/ exhaustive /;
$EXPORT_TAGS{ALL} = \@EXPORT_OK;

use strict;
use Carp;
use Scalar::Util qw/ blessed reftype /;

my $Unique = 0;
our $Vars;
our $Count;
our @Matches;
sub exhaustive {
    my $str_ref = \shift;
    my $re = shift;
    local $Vars = @_ ? \@_ : undef;

    blessed($re) && $re->isa('Regexp')
        or croak("The second argument to @{[__PACKAGE__]}::exhaustive must be a Regexp (qr//) object");

    local $Count = 0;
    local @Matches;
    my $save_match;
    {
        use re 'eval';
        if (wantarray) {
            if ($Vars) {
                my @vars = map {
                    ! ref $Vars->[$_]               ? "     \$Vars->[$_]   " :
                    reftype($Vars->[$_]) eq 'ARRAY' ? "[ \@{\$Vars->[$_]} ]" :
                    reftype($Vars->[$_]) eq 'HASH'  ? "{ \%{\$Vars->[$_]} }" :
                    croak("Unknown variable type for variable $_ in call to @{[__PACKAGE__]}::exhaustive");
                } 0 .. $#$Vars;

                my $vars = join ',', @vars;
                $vars = "[ $vars ]" if @vars > 1;

                my $pattern = "(?{push \@Matches, $vars})";

                $save_match = qr/$pattern/;
            }
            else {
                $save_match = qr/
                    (?{
                        $Vars ||= eval 'sub { \\@_ }->(' . (join(',', map "\$$_", 1 .. $#+) || '$&') .')';
                        push @Matches, @$Vars == 1 ? $Vars->[0] : [ @$Vars ];
                    })
                /x;
            }
        }
        else {
            $save_match = qr/(?{$Count++})/;
        }
    }

    $Unique++;
    $$str_ref =~ /
        (?:$Unique){0} # I don't understand why $Unique is needed to
        $re            # make qr[.*] work. Do you?
        $save_match
        (?!)
    /x;

    return wantarray ? @Matches : $Count;
}

1;

__END__

=head1 NAME

Regexp::Exhaustive - Find all possible matches, including backtracked and overlapping, of a pattern against a string


=head1 SYNOPSIS

    use Regexp::Exhaustive qw/ exhaustive /;

    print "Subsets:\n";
    print "$_\n" for exhaustive('abc' => qr/.+/);

    print "\n";

    print "Overlapping matching:\n";
    print "$_\n" for exhaustive('abc' => qr/(?>.+)/);

    print "\n";

    print "Heads and tails:\n";
    print "@$_\n" for exhaustive('abcde' => qr/^(.+?)(.+)\z/);

    print "\n";

    print "Triplets:\n";
    print "@$_\n" for exhaustive('abcde' => qr/(.)(.)(.)/);

    print "\n";

    print "Binary count:\n";
    print map(length, @$_), "\n"
        for exhaustive('111', qr/^(.??)(.??)(.??)/);

    __END__
    Subsets:
    abc
    ab
    a
    bc
    b
    c

    Overlapping matching:
    abc
    bc
    c

    Heads and tails:
    a bcde
    ab cde
    abc de
    abcd e

    Triplets:
    a b c
    b c d
    c d e

    Binary count:
    000
    001
    010
    011
    100
    101
    110
    111

=head1 DESCRIPTION

This module does an exhaustive match of a pattern against a string. That means that it will match all ways possible, including all backtracked and overlapping matches.

It works a lot like the familiar C<m//g> regarding return values.

Beware that exhaustive matching may generate a very large number of matches. If you only need overlapping matches that's easily achieved. Overlapping matching has a maximum number of matches being the length of the string plus one.

This is an initial release, and many things may change for the next version. If you feel something is missing or poorly designed, now is the time to voice your opinion.


=head1 EXPORTED FUNCTIONS

Nothing is exported by default. The C<:ALL> tag exports everything that can be exported.

=over

=item exhaustive(STRING => qr/PATTERN/)

Exhaustively generates and returns all matches in list context. Returns the number of matches in scalar context.

If the pattern doesn't contain any capturing subpatterns, the matched string (C<$&>) is returned. If only one capturing subpattern is seen (C<$1>), that is returned. Otherwise C<$1>, C<$2>, etc is returned grouped using array references.

This is like C<m//g> in list context, except C<m//g> returns all capturing subpatterns as a flat list.

This method does not effect C<pos($str)>.

=item exhaustive(STRING => qr/PATTERN/, $1, $2, $+, $^R, \@+, ...)

Optionally, you can specify which variables to return. If C<@-> and/or C<@+> is used they must be passed as references, and will end up as array references in the return list.

If two or more variables are specified they will be grouped using array references.

Beware, not using any capturing group will make C<$&> be used, with all the usual caveats.

=item overlapping(STRING => qr/PATTERN/)

If this function would exist, but it doesn't, it would be like global but try to match from every position of the string. It's like an exhaustive match that doesn't backtrack inside the pattern.

This function doesn't exist because it isn't needed. Instead use

    exhaustive(STRING => qr/(?>PATTERN)/)

i.e. wrap the pattern with the C<< (?>...) >> assertion. This will lock the match once the pattern has matched, forcing the regex engine to skip behind the pattern when backtracking, thus moving forward on string for the next match.

Using

    STRING =~ /(?=PATTERN)/g

will be faster, but has three key differences: (1) assumes C<pos()> is undefined, (2) undefines C<pos()>, and (3) returns all captured groups as a flat list. Note that saving away C<pos()> and then restoring it may cause certain global matches to loop infinitely.

    $_ = 'foo';

    while (/.??/g) {
        print pos();
        pos() = pos(); # Not really doing anything, or is it?
    }

This will loop forever.

=back


=head1 DIAGNOSTICS

=over

=item The second argument to Regexp::Exhaustive::exhaustive must be a Regexp (qr//) object

(F) Self-explanatory.

=back


=head1 EXAMPLES

See L</"SYNOPSIS"> for more examples.

=head2 Finding all divisors

A commonly known snippet of regex can be used to find out if an integer is a prime number or not.

    sub is_prime {
        my ($n) = @_;

        my $str = '.' x $n;

        return $str =~ /^(?:..+)\1+$/ ? 0 : 1;
    }

    print '9 is prime: ', is_prime(9), "\n";
    print '11 is prime: ', is_prime(11), "\n";

    __END__
    9 is prime: 0
    11 is prime: 1

Equally simple is it, with C<Regexp::Exhaustive>, to find out not only if it's a prime number, but which its divisors are.

    use Regexp::Exhaustive;

    sub divisors {
        my ($i) = @_;

        return map length, exhaustive('.' x $i => qr/^(.+?)\1*$/);
    }

    print "$_\n" for divisors(12);

    __END__
    1
    2
    3
    4
    6
    12

=head2 Finding the cross product

L<Set::CrossProduct|Set::CrossProduct> gives you the cross product of a set, and that's the good way of doing just that. But as an example, here's how you can find all possible combinations of two four-sided dice using C<Regexp::Exhaustive>. To illustrate the difference between greedy and non-greedy matches I let the second die be in reversed order.

    use Regexp::Exhaustive;

    my $sides = '1234';
    my @sets = exhaustive(
        "$sides\n$sides"
        =>
        qr/^.*?(.).*\n.*(.)/)
    );

    print "@$_\n" for @sets;

    __END__
    14
    13
    12
    11
    24
    23
    22
    21
    34
    33
    32
    31
    44
    43
    42
    41

=head2 N-ary count

Using C<Regexp::Exhaustive> you can generate all values of a certain digit length using an n-ary count. This is demonstrated for binary numbers with a length of three.

    sub all_values {
        my ($n, @base) = @_;
        my $str = (join('', @base) . "\n") x $n;
        my $re = ".*?(.).*\n" x $n;
        return map { join '', @$_ } exhaustive($str, qr/^$re/);
    }

    print "$_\n" for all_values(3, qw/ 0 1 /);

    __END__
    000
    001
    010
    011
    100
    101
    110
    111


=head1 WARNING

This module uses the experimental C<(?{ ... })> assertion. Thus this module is as experimental as that assertion.


=head1 AUTHOR

Johan Lodin <lodin@cpan.org>


=head1 COPYRIGHT

Copyright 2005-2007 Johan Lodin. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=head1 SEE ALSO

L<perlre> for regular expressions.

L<perlvar> for the special variables.

=cut
