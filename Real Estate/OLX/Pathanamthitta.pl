#!/usr/bin/perl

use strict;

use Encode;
use HTML::TreeBuilder;
use WWW::Mechanize;

my $base_url = 'http://www.olx.in/nf/real-estate-cat-16/pathanamthitta';
my $mech     = WWW::Mechanize->new();

eval { $mech->get($base_url); };
if ($@) {
    print "Error connecting to $base_url. Exitting...\n";
    exit;
}

my $tree = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));
my @detail_divs = $tree->look_down(_tag => 'div', class => 'second-column-container  table-cell');
my @price_divs  = $tree->look_down(_tag => 'div', class => 'third-column-container table-cell');
my @time_divs   = $tree->look_down(_tag => 'div', class => 'fourth-column-container table-cell');
print scalar @detail_divs . "\n";
print scalar @price_divs . "\n";
print scalar @time_divs . "\n";
#exit;

my $count = 0;
for my $div (@detail_divs) {
    my $a       = $div->look_down(_tag => 'a');
    my $link    = $a->attr('href');
    my $title   = $a->as_trimmed_text;
    my $details = $div->look_down(_tag => 'span', class => 'itemlistinginfo clearfix')->as_trimmed_text;
    my @details = map { trim($_) } split /\|/, $details;
    my $type    = pop @details;
    my $address = join ', ', @details;
    my $price   = $price_divs[$count]->as_trimmed_text;
    my $time    = $time_divs[$count]->as_trimmed_text;

    print "title: $title\n";
    print "type: $type\n";
    print "address: $address\n";
    print "price: $price\n";
    print "time: $time\n";
    print "link: $link\n";

    $count++;
    print "count: $count\n\n";
}

sub trim {
    my $string = shift;
    $string =~ s/^\s+|\s+$//g;
    return $string;
}
