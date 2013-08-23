#!/usr/bin/perl

no warnings;
use strict;

use Data::Dumper;
use Encode;
use HTML::TreeBuilder;
use utf8;
use WWW::Mechanize;

my $mech = WWW::Mechanize->new();

open (CSV, '>>', 'data.csv') || die $!;

for (1 .. 39) {
    my $scrap_url = "http://www.bnho.de/mitglieder.htm";
    if ($_ > 1) {
        my $start = ($_ - 1) * 15;
        my $end   = $start + 15;
        $scrap_url = "http://www.bnho.de/mitglieder.htm?&suchen=&suchen_fachgebiet=&nurarzt=1&zaehler_anfang=$start&zaehler_ende=$end&zaehler_gesamt=575";
    }

    print "url: $scrap_url\n";

    eval {
        $mech->get($scrap_url);
    };

    if ($@) {
        print "Error connecting to URL $scrap_url. Exitting...\n";
        last;
    }

    my $tree = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));
    my @tds = $tree->look_down(_tag => 'td', valign => 'middle', width => '210px', align => 'left');
    print scalar @tds;
    print "\n";

    my $count = 0;
    for my $td (@tds) {
        $count++;
        print "count: $count\n";
        #print $td->as_text;
        #print $td->as_text(skip_dels => 1);
        #print "\n\n";
        my $all = $td->as_trimmed_text;
        #print "$all\n";
        #exit;
        my @brs = $td->look_down(_tag => 'br');
        #print Dumper @brs;
        $brs[1]->as_trimmed_text;
        exit;

        my @brs = split /<br \/>/, $td->as_HTML;
        map { $_ =~ s/<.+?>//g; print CSV qq{"$_",}; } @brs;

        my $b = $td->look_down(_tag => 'b');
        my ($Postcode, $City);
        ($Postcode, $City) = split / /, $b->as_trimmed_text if $b;

        my $link = $td->look_down(_tag => 'a');
        $link = $link->{href} if $link;

        print CSV qq{"$Postcode","$City","$link"\n};

        #print "link: $link\n";
        #print $link->{href};
        #print Dumper $link;
        #print encode("iso-8859-1", $brs[1]);
        #print utf8::decode($brs[1]);
        #exit;

        #print "$_\n" for @brs;

        #my ($Title, $Forename, $Surname, $Street, $Postcode, $City, $Tel, $Fax, $Web);
        #print scalar @brs;
        #print "\n\n";
        #$Title = $brs[0];
        #$Title =~ s/<.+?>//g;
        #$Title =~ s/<.+?>$//;
        #print "Title: $Title\n\n";
        #print $brs[1];
        #print "\n\n";
        #print $brs[1]->as_trimmed_text;
        #print "\n\n";
        #print $brs[2]->as_trimmed_text;
        #print "\n\n";

        #print "\n\n";

        #print CSV qq{"$brs[0]","$brs[1]","$brs[2]","$brs[3]","$brs[4]","$brs[5]","$brs[6]","$brs[7]"\n};
        #print CSV qq{"$all","$all","$all","$all","$all","$all","$all","$all","$link"\n};
        #exit;
    }
}

END {
    close CSV;
}
