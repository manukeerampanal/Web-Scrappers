#!/usr/bin/perl

use strict;

use Encode;
use HTML::TreeBuilder;
use WWW::Mechanize;

my $base_url = 'http://kochi.quikr.com/Real-Estate/w867';
my $mech     = WWW::Mechanize->new();

eval { $mech->get($base_url); };
if ($@) {
    print "Error connecting to $base_url. Exitting...\n";
    exit;
}

my $tree = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));

#my @premium_divs = $tree->look_down(
#    _tag  => 'div',
#    class => 'snb_entire_ad a1d1top'
#);
#print scalar @premium_divs . "\n";

my @normal_divs = $tree->look_down(_tag => 'div', class => 'snb_entire_ad ad');
print scalar @normal_divs . "\n";

my $count = 0;
for my $div (@normal_divs) {
    my $title    = $div->look_down(_tag => 'h3', class => 'adtitlesnb')
        ->as_trimmed_text;
    my $summary  = $div->look_down(_tag => 'div', class => 'snb_ad_detail')
        ->as_trimmed_text;
    my @a        = $div->look_down(_tag => 'a', class => 'defultchi2');
    my $type     = $a[0]->as_trimmed_text;
    my $locality = $a[1]->as_trimmed_text =~ s/^In\s//r;
    my $price    = $div->look_down(_tag => 'div', class => 'snb_price_tag')
        ->as_trimmed_text;
    my $time     = $div->look_down(_tag => 'span', class => 'datef')
        ->as_trimmed_text;
    my $link    = $div->look_down(_tag => 'a', class => 'adttllnk unbold')
        ->attr('href');

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
