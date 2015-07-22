#!/usr/bin/perl

use strict;

use Parallel::ForkManager;

my @scripts = qw(
    ./OLX/Kochi.pl
    ./Quikr/Kochi.pl
    ./99acres/Kochi.pl
    ./IndiaProperty/Kochi.pl
    ./MagicBricks/Kochi.pl
    ./Click/Kochi.pl
);

my $pm = Parallel::ForkManager->new(scalar @scripts);

for my $script (@scripts) {
    print "$script\n";
    $pm->start and next;
    `/usr/bin/perl $script`;
    $pm->finish;
}
