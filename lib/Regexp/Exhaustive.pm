{
    package Regexp::Exhaustive;
    use 5.006001;

    $VERSION = 0.01;

    use strict;
    use Carp;
    use Scalar::Util qw/ blessed /;

    ###########################################################################
    # Constructor                                                             #
    ###########################################################################

    sub new {
        my $self = bless {} => shift;
        my $str_ref = \$_[0];
        my (undef, $pattern, $p) = @_;

        blessed($pattern) && $pattern->isa('Regexp')
            or croak("The second argument to @{[__PACKAGE__]}->new() must be a Regexp (qr//) object");

        %$self = (
            str_ref => $str_ref,
            orig_pattern => $pattern,
            pattern => _gen_pattern($pattern),
            pos => 0,
            count => 0,
        );

        return $self;
    }

    ###########################################################################
    # Methods                                                                 #
    ###########################################################################

    sub clone {
        my $self = shift;

        my $clone = bless { %$self }, ref $self;
        $clone->{pattern} = _gen_pattern($self->{orig_pattern});

        return $clone;
    }

    sub next {
        my $self = shift;

        my $oldp = pos ${$self->{str_ref}};
        {
            pos(${$self->{str_ref}}) = $self->{pos};

            #print $self->{pattern}, "\n";
            #use Data::Dumper; print Dumper($self->{pattern}), "\n";
            #print blessed($self->{pattern}), "\n";

            local our $curr_c = -1;
            my $backtrack = do {
                use re 'eval';
                qr/
                    (?(?{++$curr_c < $self->{count}})
                        (?!)
                    )
                /x;
            };

            my $match =
                ${$self->{str_ref}} =~ /
                    \G
                    $self->{pattern}
                    $backtrack
                /gx
                ? Regexp::Exhaustive::_Match->new(${$self->{str_ref}})
                : undef
            ;

            if (defined $match) {
                $self->{count}++;

                pos(${$self->{str_ref}}) = $oldp;

                # This is the "real" return statement.
                return $match;
            }
            else {
                $self->{pos}++;

                if ($self->{pos} > length ${$self->{str_ref}}) {
                    # There's no more matches. Stop searching.
                    last;
                }

                $self->{count} = 0;
                redo;
            }
        }

        pos(${$self->{str_ref}}) = $oldp;
        return;
    }

    sub all {
        my $self = shift;

        my $str_ref = $self->{str_ref};
        my $re = $self->{pattern};

        my @matches;
        my $save_match = do {
            use re 'eval';
            qr/(?{push @matches, Regexp::Exhaustive::_Match->new($$str_ref)})/;
        };

        $$str_ref =~ /$re$save_match(?!)/;

        return @matches;
    }

    ###########################################################################
    # Help subroutines                                                        #
    ###########################################################################

    # The $Unique thing is a workaround. If there are two identical qr//
    # objects, like $re1 = qr/./ and $re2 = qr/./ the //g match in &next
    # gets confused. Therefore I need to create unique objects. Hopefully
    # the extra string in the pattern makes the pattern unique.
    my $Unique = 0;
    sub _gen_pattern {
        my ($pattern) = @_;

        $Unique++;
        return qr/(?:@{[__PACKAGE__]}::_$Unique){0}$pattern/;
    }
}
{
    package Regexp::Exhaustive::_Match;

    use strict;
    use overload
        '""' => sub { $_[0]->match },
        fallback => 1,
    ;

    use Carp;

    # OBS: &new may not directly or indirectly use any regular expressions,
    # so that patterns that use this class inside a (?{}) still works.
    sub new {
        my $self = bless {} => shift;
        my $str_ref = \shift;

        %$self = (
            str_ref => $str_ref,

            '$+'  => $+,
            '$^N' => $^N,
            '$^R' => $^R,
            '@+'  => [ @+ ],
            '@-'  => [ @- ],

            'pos' => pos($$str_ref),
        );

        return $self;
    }

    sub prematch {
        my $self = shift;

        return substr(${$self->{str_ref}}, 0, $self->{'@-'}->[0]);
    }

    sub match { $_[0]->group(0) }

    sub postmatch {
        my $self = shift;

        return substr(${$self->{str_ref}}, $self->{'@+'}->[0]);
    }

    sub group {
        my $self = shift;
        my ($n) = @_;

        defined $self->{'@-'}->[$n]
            or return undef;

        return substr(${$self->{str_ref}}, $self->{'@-'}->[$n], $self->{'@+'}->[$n] - $self->{'@-'}->[$n]);
    }

    sub groups {
        my $self = shift;

        my $groups = $#{$self->{'@-'}};

        return wantarray
            ? map $self->group($_), 1 .. $groups
            : $groups;
    }

    sub pos { $_[0]->{pos} }

    my %methods = (
        q{$&} => sub { $_[0]->match },
        q{$`} => sub { $_[0]->prematch },
        q{$'} => sub { $_[0]->postmatch },

        '$+'  => sub { $_[0]->{'$+'}  },
        '$^N' => sub { $_[0]->{'$^N'} },
        '$^R' => sub { $_[0]->{'$^R'} },

        '@+' => sub { @{$_[0]->{'@+'}} },
        '@-' => sub { @{$_[0]->{'@-'}} },
    );
    my %aliases = qw/
        $MATCH                      $&
        $PREMATCH                   $`
        $POSTMATCH                  $'

        $LAST_PAREN_MATCH           $+
        $LAST_REGEXP_CODE_RESULT    $^R

        @LAST_MATCH_END             @+
        @LAST_MATCH_START           @-
    /;
    $methods{$_} = $methods{$aliases{$_}}
        for keys %aliases;

    sub var {
        my $self = shift;
        my ($var) = @_;

        my $method = $methods{$var} ||= $var =~ s/\$(?=([^\D0]\d*)\z)//
            ? sub { $_[0]->group($var) }
            : undef
                or croak(__PACKAGE__ . ": No such variable \"$var\"");

        return $self->$method;
    }
}

1;

__END__

=head1 NAME

Regexp::Exhaustive - Find all possible matches, including backtracked and overlapping, of a pattern against a string


=head1 SYNOPSIS

    use Regexp::Exhaustive;

    my @matches = Regexp::Exhaustive->new('abc' => qr/.+?/)->all;

    my $matcher = Regexp::Exhaustive->new('abc' => qr/.+?/);
    while (my ($match) = $matcher->next) {
        print "$match\n";
    }

    __END__
    a
    ab
    abc
    b
    bc
    c


=head1 DESCRIPTION

This module does an exhaustive match of a pattern against a string. That means that it will match all ways possible, including all backtracked and overlapping matches.

The main advantage this module provides is the iterator interface. It enables you to have arbitrary code between each match without loading every match into the memory first. The price you pay for this is efficiency, as the regex engine has to do extra work to resume the matching at the right place.

As a convenience the C<all> method is provided. Currently it isn't just convenient though. It's also more efficient than iterating through the matches using C<next>. This may change though.

This is an initial release, and many things may change for the next version. If you feel something is missing or poorly designed, now is the time to voice your opinion.


=head1 METHODS

=head2 For C<Regexp::Exhaustive>

=over

=item $matcher = Regexp::Exhaustive->new($str => qr/$pattern/)

C<new> creates a new C<Regexp::Exhaustive> object. The first argument is a string and the second is a C<qr//> object.

Do not change the string while using this object or any associated match objects. Copy the string first if you plan to use. That's easily done by quoting it in the call:

    my $matcher = Regexp::Exhaustive->new("$str" => qr/$pattern/);

Currently the behaviours of C<(?{})> and C<(??{})> assertions in a pattern given to C<Regexp::Exhaustive> are undefined.

=item $clone = $matcher->clone

Creates a clone of C<$matcher>. Note that C<$str> still will be referenced.

=item $match = $matcher->next

Returns a match object for the next match. If there's no such match then C<undef> is returned in scalar context and the empty list in list context.

=item @matches = $matcher->all

Generates and returns all matches in list context. Returns the number of matches in scalar context. This method may interfere with the C<next> method, so if you mix C<next> and C<all>, call C<all> on a clone:

    my @matches = $matcher->clone->all;

=back

=head2 For the match object

Match objects are overloaded to return the matched string (the value of method C<match>).

=over

=item $match->var('$SPECIAL_VARIABLE');

Returns the value of C<$SPECIAL_VARIABLE> associated with the match. Arrays return their elements in list context and their sizes in scalar context. Supported variables:

    Punctuation:    English:
    $<*digits*>
    $&              $MATCH
    $`              $PREMATCH
    $'              $POSTMATCH
    $+              $LAST_PAREN_MATCH
    $^N
    @+              @LAST_MATCH_END
    @-              @LAST_MATCH_START
    $^R             $LAST_REGEXP_CODE_RESULT

Example:

    my $str = 'asdf';
    my $match = Regexp::Exhaustive::->new($str => qr/.(.)/)->next;

    print $match->var('$1'), "\n";
    print $match->var('$POSTMATCH'), "\n";
    print join(' ', $match->var('@-')), "\n";

    __END__
    s
    df
    0 1

=item $match->prematch

Returns the equivalent of C<$`>.

=item $match->match

Returns the equivalent of C<$&>.

=item $match->postmatch

Returns the equivalent of C<$'>.

=item $match->group($n)

Returns the C<$n>:th capturing group. Equivalent to C<< $<*digits*> >>. C<$n> must be strictly positive.

=item $match->groups

Returns all capturing groups in list context. Returns the number of groups in scalar context.

=item $match->pos

Returns the equivalent of C<pos($str)>.

=back


=head1 DIAGNOSTICS

=over

=item The second argument to Regexp::Exhaustive->new() must be a Regexp (qr//) object

(F) Self-explanatory.

=back


=head1 EXAMPLES

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

        return
            map length $_->group(1),
                Regexp::Exhaustive::
                    ->new('.' x $i => qr/^(.+?)\1*$/)
                    ->all
        ;
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
    my $matcher = Regexp::Exhaustive::->new(
        "$sides\n$sides" => qr/^.*?(.).*\n.*(.)/
    );

    while (my ($match) = $matcher->next) {
        print $match->groups, "\n";
    }

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

=head2 Finding all subsets

See L</SYNOPSIS>.


=head1 WARNING

This module uses the experimental C<(?{ code })> and C<(?(condition)yes-pattern|no-pattern))> assertions. Thus this module is as experimental as those assertions.


=head1 AUTHOR

Johan Lodin <lodin@cpan.org>


=head1 COPYRIGHT

Copyright 2005-2007 Johan Lodin. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=head1 SEE ALSO

L<perlre> for regular expressions.

L<perlvar> for the special variables.

=cut
