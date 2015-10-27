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
# my $sth = $db->prepare_replace($source) || exit;
my $sth = $db->{dbh}->prepare("
    REPLACE INTO ad
        (city, source, title, type, summary, locality, price, time, link, contact_number)
    VALUES
        (?, '$source', ?, ?, ?, ?, ?, ?, ?, ?)
") or die $db->{dbh}->errstr;

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

        my ($time, $type) = split /\s+\|\s+/, $div->look_down(_tag => 'span', class => 'roomTextDesc')->as_trimmed_text;
        $time =~ s/^Posted: //;
        $time =~ s/by .+$//;
        $type =~ s/ - .+$//;

        print "title: $title\n";
        print "type: $type\n";
        print "locality: $locality\n";
        print "price: $price\n";
        print "time: $time\n";
        print "link: $link\n";

        my ($summary, $contact_number);
        my $details_mech = WWW::Mechanize->new();

        eval { $details_mech->get($link); };
        if ($@) {
            print "Error connecting to $link. Skipping...\n";
        } else {
            my $details_tree = HTML::TreeBuilder->new_from_content(decode_utf8($details_mech->content()));

            my $summary_div = $details_tree->look_down(_tag => 'p', class => 'clickin-normalText');
            $summary        = $summary_div->as_trimmed_text if $summary_div;

            my $contact_number_div = $details_tree->look_down(_tag => 'div', class => 'clickin-mobileNum phoneText');
            $contact_number        = $contact_number_div->as_trimmed_text if $contact_number_div;
        }

        $summary .= "\n\n" . $div->look_down(_tag => 'div', class => 'clickin-postsDesc1')->as_trimmed_text;

        print "summary: $summary\n";
        print "contact_number: $contact_number\n";
        # exit;

        $count++;
        print "count: $count\n\n";

        $sth->execute($city, $title, $type, $summary, $locality, $price, $time, $link, $contact_number) or next ad;

        $total_count++;
        print "total count: $total_count\n\n";
    }
}
