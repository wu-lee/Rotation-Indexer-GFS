#!/usr/bin/perl
package main;
use Test::More tests => 3;
use Test::Exception;
use strict;
use warnings;
use Carp qw(croak);

use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/lib";


my $class = 'Rotation::Indexer::GFS';

use_ok $class;

# Note, indexes should continue to cycle backwards (negative offsets)
# as well as forwards.

my @cases = (
    
    [[3, 2, 2] => [-15..15] => [
        qw(0-1
           1
           2
           0-0-0
           1
           2
           0-1
           1
           2
           0-0-1
           1
           2
           0-1
           1
           2
           0-0-0
           1
           2
           0-1
           1
           2
           0-0-1
           1
           2
           0-1
           1
           2
           0-0-0
           1
           2
           0-1)
    ]],

    [[2, 3, 4] => [-25..25] => [
        qw(1
           0-0-0
           1
           0-1
           1
           0-2
           1
           0-0-1
           1
           0-1
           1
           0-2
           1
           0-0-2
           1
           0-1
           1
           0-2
           1
           0-0-3
           1
           0-1
           1
           0-2
           1
           0-0-0
           1
           0-1
           1
           0-2
           1
           0-0-1
           1
           0-1
           1
           0-2
           1
           0-0-2
           1
           0-1
           1
           0-2
           1
           0-0-3
           1
           0-1
           1
           0-2
           1
           0-0-0
           1)
    ]],

);


foreach my $case (@cases) {
    my ($cycles, $steps, $expected) = @$case;
            
    my $obj = $class->new(@$cycles);

    my @ids = map { join "-", $obj->index($_) } @$steps;

    is_deeply \@ids, $expected, 
        "correct id sequence for (@$cycles) cycle";
}
