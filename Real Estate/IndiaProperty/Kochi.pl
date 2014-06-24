#!/usr/bin/perl

use strict;

use Encode;
use HTML::TreeBuilder;
use WWW::Mechanize;

my $base_url   = 'http://www.indiaproperty.com/';
my $search_url = 'http://www.indiaproperty.com/ernakulam-properties';
my $mech       = WWW::Mechanize->new();

eval { $mech->get($search_url); };
if ($@) {
    print "Error connecting to $search_url. $@ Exitting...\n";
    exit;
}

my $tree = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));

my @divs = $tree->look_down(_tag => 'div', class => 'srcwidth');
#print scalar @divs . "\n";
#exit;

my $count = 0;
for my $div (@divs) {
    my $a        = $div->look_down(_tag => 'a');
    my $title    = $a->as_trimmed_text;
    my $link     = $base_url . $a->attr('href');
    my $price    = $div->look_down(_tag => 'div', class => 'txt22 boldtxt paddb10')->as_trimmed_text;
    my $locality = $div->look_down(_tag => 'span', class => 'clr6')->as_trimmed_text;
    $locality    =~ s/, .+$//;
    my $time     = $div->look_down(_tag => 'span', class => 'txt11 clr3')->as_trimmed_text;
    $time        =~ s/^.+Created on: //;
    my $summary  = $div->look_down(_tag => 'div', class => 'txt12')->as_trimmed_text;

    print "title: $title\n";
    print "summary: $summary\n";
    #print "type: $type\n";
    print "locality: $locality\n";
    print "price: $price\n";
    print "time: $time\n";
    print "link: $link\n";
    exit;

    $count++;
    print "count: $count\n\n";
}

sub trim {
    my $string = shift;
    $string =~ s/^\s+|\s+$//g;
    return $string;
}
