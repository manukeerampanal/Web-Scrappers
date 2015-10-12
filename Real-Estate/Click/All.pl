#!/usr/bin/perl

use lib '/root/Real-Estate/lib';
use strict;

use Database;
use Conf;

use Encode;
use HTML::TreeBuilder;
use WWW::Mechanize;

my $source = 'Click';

my $db  = Database->new;
my $sth = $db->prepare_replace($source) || exit;

my $conf   = Conf->new;
my $cities = $conf->{city}{$source};

my $total_count = 0;

city:
for my $city (sort keys %$cities) {
    my $url  = $cities->{$city};
    my $mech = WWW::Mechanize->new();

    eval { $mech->get($url); };
    if ($@) {
        print "Error connecting to $url. Skipping...\n";
        next city;
    }

    my $tree = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));
    my @divs = $tree->look_down(_tag => 'div', class => 'clickin-listingpagePostsRight');
    print scalar @divs . "\n";
    #exit;

    my $count = 0;
    ad:
    for my $div (@divs) {
        my $a     = $div->look_down(_tag => 'a');
        my $title = $a->as_trimmed_text;
        my $link  = $a->attr('href');

        my $locality;
        my @b     = $div->look_down(_tag => 'b');
        $locality = $b[1]->as_trimmed_text if @b;

        my $price;
        my $price_div = $div->look_down(_tag => 'div', class => 'clickin-postsPriceDetails');
        $price        = $price_div->as_trimmed_text if $price_div;

        my $summary = $div->look_down(_tag => 'div', class => 'clickin-postsDesc')->as_trimmed_text;
        $summary   .= ', ' . $div->look_down(_tag => 'div', class => 'clickin-postsDesc1')->as_trimmed_text;

        my ($time, $type) = split /\s+\|\s+/, $div->look_down(_tag => 'span', class => 'roomTextDesc')->as_trimmed_text;
        $time =~ s/^Posted: //;
        $time =~ s/by .+$//;
        $type =~ s/ - .+$//;

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

        $sth->execute($city, $title, $type, $summary, $locality, $price, $time, $link) or next ad;

        $total_count++;
        print "total count: $total_count\n\n";
    }
}
