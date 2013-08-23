#!/usr/bin/perl -X

use Compress::Zlib;
use Data::Dumper;
use Encode;
use Scrappy;
use Scrappy::Scraper::Parser;
use strict;

my $scraper = Scrappy->new;

my $base_url = 'http://www.lats.org/directory.php';

open (CSV, '>>', 'data.csv') || die $!;

my $total_count = 0;

for my $page (1 .. 60) {
    my $count = 0;

    my $url = $base_url;
    $url .= "?pagina=$page" if $page > 1;
    print "url: $url\n";

    $scraper->get($url);
    my $data = $scraper->page_data;

    my  $parser = Scrappy::Scraper::Parser->new;
    $parser->select('p', $data);

    $parser->each(sub{
        $count++;
        $total_count++;

        #print Dumper shift->{html} . "\n";
        my $content = shift->{html};
        my @lines = split /<br \/>/, $content;
        for (@lines) {
            $_ =~ s/<.+?>//g;
            $_ = trim($_);
        }

        my ($surname, $rem) = split /,/, $lines[0];
        my ($forename, $type, $since) = split /-/, $rem;

        #my ($name, $type, $since) = split /-/, $lines[0];
        #$name  = trim($name);
        $type  = trim($type);
        $since = trim($since);

        #my ($surname, $forename) = split /,/, $name;
        $surname  = trim($surname);
        $forename = trim($forename);
        print "$surname, $forename, $type, $since\n";
        print qq{$lines[$_], } for 1 .. $#lines;
        print "\n";

        print CSV qq{$page\t$count\t$total_count\t};
        print CSV qq{$surname\t$forename\t$type\t$since\t};
        print CSV qq{$lines[$_]\t} for 1 .. $#lines;
        print CSV "\n";
    });
}

sub trim($) {
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}
