#!/usr/bin/perl

use strict;

use Parallel::ForkManager;

my @scripts = qw(
    /root/Real-Estate/OLX/All.pl
    /root/Real-Estate/99Acres/All.pl
    /root/Real-Estate/IndiaProperty/All.pl
    /root/Real-Estate/MagicBricks/All.pl
    /root/Real-Estate/Click/All.pl
    /root/Real-Estate/Quikr/All.pl
);

my $pm = Parallel::ForkManager->new(scalar @scripts);

for my $script (@scripts) {
    print "$script\n";
    $pm->start and next;
    `/usr/bin/perl $script`;
    $pm->finish;
}
