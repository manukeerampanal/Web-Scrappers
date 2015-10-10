#!/usr/bin/perl

use strict;

use Parallel::ForkManager;

my @scripts = qw(
    ./OLX/All.pl
    ./Quikr/All.pl
    ./99Acres/All.pl
    ./IndiaProperty/All.pl
    ./MagicBricks/All.pl
    ./Click/All.pl
);

my $pm = Parallel::ForkManager->new(scalar @scripts);

for my $script (@scripts) {
    print "$script\n";
    $pm->start and next;
    `/usr/bin/perl $script`;
    $pm->finish;
}
