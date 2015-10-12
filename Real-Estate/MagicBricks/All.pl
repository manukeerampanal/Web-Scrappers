#!/usr/bin/perl

use lib '/root/Real-Estate/lib';
use strict;

use Database;
use Conf;

use Encode;
use HTML::TreeBuilder;
use WWW::Mechanize;

my $source = 'MagicBricks';

my $db  = Database->new;
my $sth = $db->prepare_replace($source) || exit;

my $conf   = Conf->new;
my $cities = $conf->{city}{$source};

my $base_url    = 'http://www.magicbricks.com';
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
    my @divs = $tree->look_down(_tag => 'div', class => 'srpBlock srpContentImageWrap ');
    push @divs, $tree->look_down(_tag => 'div', class => 'srpBlock srpContentImageWrap srpStartA');
    print scalar @divs . "\n";
    # exit;

    my $count = 0;
    ad:
    for my $div (@divs) {
        my $title      = $div->look_down(_tag => 'p', class => 'proHeading')->as_trimmed_text;
        my ($locality) = $div->look_down(_tag => 'span', class => 'localityFirst')->as_trimmed_text;
        my $price      = $div->look_down(_tag => 'span', class => 'proPriceField')->as_trimmed_text;

        my $time = $div->look_down(_tag => 'span', class => 'proPostedBy')->as_trimmed_text;
        $time    =~ s/^Posted:? //;

        my @summary = $div->look_down(_tag => 'div', class => 'proDetailLine');
        my $label   = $summary[1]->look_down(_tag => 'label')->as_trimmed_text;
        my $summary = $summary[1]->as_trimmed_text;
        $summary    =~ s/^$label//;

        my $amenitiesListing = $div->look_down(_tag => 'div', class => 'amenitiesListing');
        if ($amenitiesListing) {
            my @li   = $amenitiesListing->look_down(_tag => 'li');
            $summary .= ', ' . join ', ', map { $_->as_trimmed_text } @li if @li;
        }

        # my $type     = join ', ', map { $_->as_trimmed_text } $ul[1]->look_down(_tag => 'li');
        my $a    = $div->look_down(_tag => 'span', class => 'seeProDetail')->look_down(_tag => 'a');
        my $link = $base_url . $a->attr('href');

        print "title: $title\n";
        print "summary: $summary\n";
        # print "type: $type\n";
        print "locality: $locality\n";
        print "price: $price\n";
        print "time: $time\n";
        print "link: $link\n";
        # exit;

        $count++;
        print "count: $count\n\n";

        $sth->execute($city, $title, undef, $summary, $locality, $price, $time, $link) or next ad;

        $total_count++;
        print "total count: $total_count\n\n";
    }
}
