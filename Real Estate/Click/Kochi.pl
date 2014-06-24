#!/usr/bin/perl

use strict;

use Encode;
use HTML::TreeBuilder;
use WWW::Mechanize;

my $search_url = 'http://cochin.click.in/real-estate-c39';
my $mech       = WWW::Mechanize->new();

eval { $mech->get($search_url); };
if ($@) {
    print "Error connecting to $search_url. $@ Exitting...\n";
    exit;
}

my $tree = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));
my @divs = $tree->look_down(_tag => 'div', class => 'clickin-listingpagePostsRight');
print scalar @divs . "\n";
#exit;

my $count = 0;
for my $div (@divs) {
    my $a        = $div->look_down(_tag => 'a');
    my $title    = $a->as_trimmed_text;
    my $link     = $a->attr('href');
    my @b        = $div->look_down(_tag => 'b');
    my $locality = $b[1]->as_trimmed_text;
    my $price    = ($div->look_down(_tag => 'span'))[1]->as_trimmed_text;
    my $summary  = $div->look_down(_tag => 'div', class => 'clickin-postsDesc1')->as_trimmed_text;
    my ($time, $type) = split /\s+\|\s+/, $div->look_down(_tag => 'span', class => 'roomTextDesc')->as_trimmed_text;
    $time        =~ s/^Posted: //;
    $type        =~ s/ - .+$//;

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
