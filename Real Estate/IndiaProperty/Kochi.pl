#!/usr/bin/perl

use lib "../lib";
use strict;

use Database;

use Encode;
use HTML::TreeBuilder;
use WWW::Mechanize;

my $db  = Database->new;
my $sth = $db->prepare_insert('Kochi', 'IndiaProperty') || exit;

my $base_url   = 'http://www.indiaproperty.com/';
my $search_url = 'http://www.indiaproperty.com/ernakulam-properties';
my $mech       = WWW::Mechanize->new();

eval { $mech->get($search_url); };
if ($@) {
    print "Error connecting to $search_url. $@ Exitting...\n";
    exit;
}

my $tree = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));

my @divs = $tree->look_down(_tag => 'div', class => 'property-gid-info propety-info');
my @time_divs = $tree->look_down(_tag => 'div', class => 'prop-tab-lists clearfix');
print scalar @divs . "\n";
print scalar @time_divs . "\n";
# exit;

my $count = 0;
ad:
for my $div (@divs) {
    my $a        = ($div->look_down(_tag => 'a'))[0];
    my $title    = $a->as_trimmed_text;
    my $link     = $a->attr('href');

    my $price    = $div->look_down(_tag => 'div', class => 'prop-price-info')->as_trimmed_text;

    my $title_p  = $div->look_down(_tag => 'div', class => 'prop-title')->look_down(_tag => 'p')->as_trimmed_text;
    my @title_p  = split /, /, $title_p;
    my $type     = $title_p[0];
    my $locality = $title_p[1];

    my $time     = $time_divs[$count]->as_trimmed_text;
    $time        =~ s/.+Last Updated//;

    my @li       = $div->look_down(_tag => 'div', class => 'row')->look_down(_tag => 'li');
    my $summary;
    $summary    .= join ', ', map { $_->as_trimmed_text } @li;
    $summary    .= ', ' . $div->look_down(_tag => 'p', class => 'prop-desc')->as_trimmed_text;

    print "title: $title\n";
    print "summary: $summary\n";
    print "type: $type\n";
    print "locality: $locality\n";
    print "price: $price\n";
    print "time: $time\n";
    print "link: $link\n";
    # exit;

    $count++;
    print "count: $count\n\n";

    $sth->execute($title, $type, $summary, $locality, $price, $time, $link)
        or next ad;
}
