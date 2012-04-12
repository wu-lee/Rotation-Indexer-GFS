package Rotation::Indexer::GFS;

use warnings;
use strict;
use Carp qw(croak);

use version; our $VERSION = qv('0.1');

sub new {
    my $class = shift;

    my @cycle_sizes = @_;

    @cycle_sizes > 0
        or croak "there must be at least one cycle";

    my @invalids = grep { int($_) != $_ || $_ < 1 } @cycle_sizes;

    @invalids
        and croak "the following cycle sizes are not positive integers: @invalids";

    return bless \@cycle_sizes, $class;
}

sub cycles {
    my $self = shift;
    return @$self;
}

# calculate an index from a number and a list of cycle sizes.
sub index {
    my $self = shift;
    my $offset = shift;
    defined $offset
        or croak "you must supply an offset";

    @_
        and croak "too many arguments";

    # truncate the offset
    $offset = int $offset;


    # Construct a set of sequence numbers
    # (a bit like a variable-radix numeral)
    my @seq_numbers = map {
        my $mod = $offset % $_;
        $offset = int($offset/$_);
        $mod;
    } $self->cycles;

    # Now, collapse this sequence such that only the first of each
    # cycle is significant (i.e. kept). We do this by keeping all
    # numbers up to the first non-zero (starting from the left).
    #
    # For example, with @cycles_sizes = 3, 2 2:
    # day   seq#     ID
    #  0 :  0 0 0 -> 0 0 0
    #  1 :  1 0 0 -> 1
    #  2 :  2 0 0 -> 2
    #  3 :  0 1 0 -> 0 1
    #  4 :  1 1 0 -> 1
    #  5 :  2 1 0 -> 2
    #  6 :  0 0 1 -> 0 0 1
    #  7 :  1 0 1 -> 1
    #  8 :  2 0 1 -> 2
    #  9 :  0 1 1 -> 0 1
    # 10 :  1 1 1 -> 1
    # 11 :  2 1 1 -> 2


    my $nonzeros = 0;
    return grep { $nonzeros++ if $_ || $nonzeros; $nonzeros <= 1 } @seq_numbers;
}


no Carp;
1; # Magic true value required at end of module
__END__

=head1 NAME

Rotation::Indexer::GFS - compute index numbers for Grandfather-Father-Son backup rotation schemes


=head1 VERSION

This document describes Rotation::Indexer::GFS version 0.1


=head1 SYNOPSIS

Given a definition of a cyclic rotation scheme (A.K.A. a "Grandfather
Father Son" rotation scheme), and an integral sequence number
C<compute_index> will return an index for it.

    use Rotation::Indexer::GFS;

    my $indexer = Rotation::Indexer::GFS->new(7, 4, 3);

    my $start_day = 0; # or whatever
    my @index = $indexer->index(today - $start_day); 

    my $backup_file = join("-", @index) . ".backup"; # 0-0-0.backup

  
=head1 DESCRIPTION

=head2 Why use this module?

Suppose you have a file for which you want a rotating back-up: you
want a backed-up copy of the file from each day in the last week.

To keep the backup script simple you might name the copy after the day
of the week: C<"$dow.backup">.  Then when Monday rolls around again,
the script simply copies the latest version over the file
"Monday.backup".  In other words, you don't need to explicitly prune
old files because they get overwritten by newer ones.

Now imagine a more complicated use case: you want a nested backup
rotation scheme: one copy for each day of the last week, one from each
week in the last month, and one for each of the last three months.
You might attempt to invent a naming scheme like "$month-$week-$day",
but it gets tricky because you can't simply use names like before
(unless you're happy with the schedule that calendar names impose on
you).

This is what Rotation::Indexer::GFS is for: naming backups so that you
don't need to explicitly prune old files because they get overwritten
by newer ones.  Except it supports arbitrarily nested rotations (so
long as they're regular).

For example, given a nested list of rotation periods like this:

    7, 4, 3

Which means, keep a copy for:

=over 4

=item *

each of the last 7 days (i.e. 1 week),

=item *

each week of the 4x7 days (i.e. 1 month), and

=item *

each month of the last 3x4x7 days (i.e. 3 months).

=back

Rotation::Indexer::GFS can calculate an index for any day after (or before)
the start date which maps the day into a "slot" in your rotation
scheme.  Anything in that slot can be overwritten.  The scheme
guarantees you have at least one copy from each hierarchy in the
cycle.

    my $indexer = Rotation::Indexer::GFS->new(7, 4, 3);

    my $start_day = 0; # or whatever
    my @index = $indexer->index(today - $start_day); 

    my $backup_file = join("-", @index) . ".backup"; # 0-0-0.backup

Using an index to implement your backup script makes your (log, backup
or otherwise) script simpler and less error prone: if your backups are
named like this example, you don't even need to query your backup
store to see what to prune.

Saying that, you might prefer to insert additional data into your file
name, like this:

    my $backup_file = sprintf "%s-%s-%s.%d-%d-%d.backup", $year, $month, $day, @index;

In this case you I<do> need to prune the files, but having a unique
index for rotations like this makes it relatively easy to find files
to prune - simply delete any file with the same index as a newer one.

=head2 Cycle example

For example, given

    $ixr = Rotation::Indexer::GFS->new(3, 2, 2);

And assuming you generate an index like this:

    $ID = join '-', $ixr->index($day)

Then the sequence of indexes would be:

    # $day  $ID
        0   0-0-0
        1   1
        2   2
        3   0-1
        4   1
        5   2
        6   0-0-1
        7   1
        8   2
        9   0-1
       10   1
       11   2

The slots are therefore:

      1
      2
      0-1
      0-0-0
      0-0-1

i.e You will be keeping a maximum of 5 copies.


=head1 INTERFACE

=head2 C<< $obj = $class->new(@cycles) >>

Creates a new instance which an be used to generate indexes for the
given nested cycle periods.

=head2 C<< @index = $obj->index($offset) >>

Generates the index number for a given offset from the start.
C<$offset> can be any positive or negative number/ Floating point
values will be truncated using C<int> to get an integer offset.

It returns a list of one or more positive integers.  The maximum
length of this list is the number of cycles.

=head2 C<< @cycles = $obj->cycles >>

Returns the cycle periods supplied to the constructor.

=head1 DIAGNOSTICS

=over

=item "there must be at least one cycle"

You called the constructor with no arguments.

=item "the following cycle sizes are not positive integers: ..."

You called the constructor with invalid arguments.

=item "you must supply an offset"

You called the index function with no arguments.

=item "too many arguments"

You called the index function with more than one argument.

=back


=head1 CONFIGURATION AND ENVIRONMENT
  
Rotation::Indexer::GFS requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-Rotation-Indexer-GFS@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Nick Stokoe  C<< <wu-lee@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Nick Stokoe C<< <wu-lee@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
