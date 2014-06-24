#!/usr/bin/perl

use strict;

use Encode;
use HTML::TreeBuilder;
use WWW::Mechanize;

my $base_url   = 'http://www.magicbricks.com';
my $search_url = 'http://www.magicbricks.com/property-for-sale/ALL-RESIDENTIAL-real-estate-Kochi';
my $mech       = WWW::Mechanize->new();

eval { $mech->get($search_url); };
if ($@) {
    print "Error connecting to $search_url. $@ Exitting...\n";
    exit;
}

my $tree = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));
my @divs = $tree->look_down(_tag => 'div', class => 'resultBlockWrapper bVersion');
#print scalar @divs . "\n";
#exit;

my $count = 0;
for my $div (@divs) {
    my $title    = $div->look_down(_tag => 'div', class => 'headingLeft')->as_trimmed_text;
    my ($locality) = $title =~ m/^.+in (.+)$/;
    my $price    = $div->look_down(_tag => 'span', class => 'price')->as_trimmed_text;
    my $time     = $div->look_down(_tag => 'div', class => 'postedBy')->as_trimmed_text;
    $time        =~ s/^Posted on //;
    my @ul       = $div->look_down(_tag => 'ul');
    my $summary  = join ', ', map { $_->as_trimmed_text } $ul[0]->look_down(_tag => 'li');
    my $type     = join ', ', map { $_->as_trimmed_text } $ul[1]->look_down(_tag => 'li');
    my $a        = $div->look_down(_tag => 'div', class => 'headingLeft')->look_down(_tag => 'a');
    my $link     = $base_url . $a->attr('href');

    print "title: $title\n";
    print "summary: $summary\n";
    print "type: $type\n";
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
