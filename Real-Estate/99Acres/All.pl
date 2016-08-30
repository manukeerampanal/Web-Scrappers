#!/usr/bin/perl

use lib '/root/Real-Estate/lib';
use strict;

use Database;
use Conf;

use Encode;
use HTML::TreeBuilder;
use WWW::Mechanize;

my $source = '99Acres';

my $db  = Database->new;
my $sth = $db->prepare_replace($source) || exit;

my $conf   = Conf->new;
my $cities = $conf->{city}{$source};

my $base_url    = 'http://www.99acres.com';
my $total_count = 0;

city:
for my $city (sort keys %$cities) {
    my $url  = $cities->{$city};
    my $mech = WWW::Mechanize->new();
    $mech->agent_alias('Linux Mozilla');

    eval { $mech->get($url); };
    if ($@) {
        print "Error connecting to $url - $@. Skipping...\n";
        next city;
    }

    my $tree       = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));
    my @divs       = $tree->look_down(_tag => 'div', class => qr/_srpttl srpttl/);
    my @desc_divs  = $tree->look_down(_tag => 'div', class => 'lf  f12 wBr');
    my @time_divs  = $tree->look_down(_tag => 'div', class => 'lf f13 hm10 mb5');
    my @title_divs = $tree->look_down(_tag => 'a', class => 'b wWrap');
    print "divs: " . scalar @divs . "\n";
    print "desc_divs: " . scalar @desc_divs . "\n";
    print "time_divs: " . scalar @time_divs . "\n";
    print "title_divs: " . scalar @title_divs . "\n";
    #exit;

    my $count = 0;
    ad:
    for my $div (@divs) {
        my @b     = $div->look_down(_tag => 'b');
        my $price = join ' ', map { $_->as_trimmed_text } @b;

        my ($title, $locality) = $title_divs[$count]->as_trimmed_text =~ m/(.+) in (.+)/;

        my $summary = $desc_divs[$count]->as_trimmed_text;
        $summary    =~ s/^Description : //;

        my $link = $base_url . $title_divs[$count]->attr('href');

        my $time;
        if ($time_divs[$count]) {
            $time = $time_divs[$count]->as_trimmed_text;
            $time =~ s/^.+?Posted : //;
        }

        #my @a    = $div->look_down(_tag => 'a', class => 'defultchi2');
        #my $type = $a[0]->as_trimmed_text;

        $count++;
        print "count: $count\n\n";

        $sth->execute($city, $title, undef, $summary, $locality, $price, $time, $link) or next ad;

        $total_count++;
        print "total count: $total_count\n\n";
    }
}
