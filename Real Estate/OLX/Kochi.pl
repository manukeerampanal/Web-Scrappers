#!/usr/bin/perl

use lib "./lib";
use strict;

use Database;
use Utils;

use Encode;
use HTML::TreeBuilder;
use WWW::Mechanize;

my $db  = Database->new;
my $sth = $db->prepare_insert('Kochi', 'OLX') || exit;

my $utils = Utils->new;

my $base_url = 'http://olx.in/kochi/real-estate/';
my $mech     = WWW::Mechanize->new();

eval { $mech->get($base_url); };
if ($@) {
    print "Error connecting to $base_url. Exitting...\n";
    exit;
}

my $tree = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));
my @title_divs = $tree->look_down(_tag => 'h3', class => 'large lheight20 margintop10');
my @detail_divs = $tree->look_down(_tag => 'p', class => 'color-9 lheight14 margintop3');
my @price_divs  = $tree->look_down(_tag => 'strong', class => 'c000');
my @time_divs   = $tree->look_down(_tag => 'p', class => 'color-9 lheight14 margintop3 small');
print scalar @title_divs . "\n";
print scalar @detail_divs . "\n";
print scalar @price_divs . "\n";
print scalar @time_divs . "\n";
# exit;

my $count = 0;
ad:
for my $div (@title_divs) {
    my $a        = $div->look_down(_tag => 'a');
    my $link     = $a->attr('href');
    my $title    = $div->as_trimmed_text;

    my $type     = $detail_divs[$count]->as_trimmed_text;
    my $locality = $detail_divs[$count]->look_down(_tag => 'span')->as_trimmed_text;
    $type        =~ s/$locality$//;

    my $price    = $price_divs[$count]->as_trimmed_text;
    my $time     = $time_divs[$count]->as_trimmed_text;

    print "title: $title\n";
    # print "summary: $summary\n";
    print "type: $type\n";
    print "locality: $locality\n";
    print "price: $price\n";
    print "time: $time\n";
    print "link: $link\n";
    # exit;

    $count++;
    print "count: $count\n\n";

    $sth->execute($title, $type, undef, $locality, $price, $time, $link)
        or next ad;
}
