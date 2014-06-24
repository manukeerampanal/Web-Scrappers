#!/usr/bin/perl

use lib './lib';
use strict;

use Conf;
use DBI;

use Encode;
use HTML::TreeBuilder;
use WWW::Mechanize;

my %cities = (
    # The below 3 cities don't have their own city-wise URLs. So they should
    # be scraped first so that the ads will be come under their own cities.
    # Otherwise they will go to other cities. However, these ads will be
    # repeated for the next scraps also, but will be skipped by the MySQL
    # unique constraint.
    Idukki             => 'http://www.olx.in/nf/real-estate-cat-16/idukki',
    Pathanamthitta     => 'http://www.olx.in/nf/real-estate-cat-16/pathanamthitta',
    Wayanad            => 'http://www.olx.in/nf/real-estate-cat-16/wayanad',

    Alappuzha          => 'http://alappuzha.olx.in/real-estate-cat-16',
    Kannur             => 'http://kannur.olx.in/real-estate-cat-16',
    Kasaragod          => 'http://kasaragod.olx.in/real-estate-cat-16',
    Kochi              => 'http://kochi.olx.in/real-estate-cat-16',
    Kollam             => 'http://kollam.olx.in/real-estate-cat-16',
    Kottayam           => 'http://kottayam.olx.in/real-estate-cat-16',
    Kozhikode          => 'http://kozhikode.olx.in/real-estate-cat-16',
    Malappuram         => 'http://malappuram.olx.in/real-estate-cat-16',
    Palakkad           => 'http://palakkad.olx.in/real-estate-cat-16',
    Thiruvananthapuram => 'http://thiruvananthapuram.olx.in/real-estate-cat-16',
    Thrissur           => 'http://thrissur.olx.in/real-estate-cat-16',
);

my $conf = Conf->new;
my $dbh  = db_connect();
my $sth  = $dbh->prepare("
    INSERT INTO ad
        (city, source, title, type, summary, locality, price, time, link)
    VALUES
        (?, 'OLX', ?, ?, ?, ?, ?, ?, ?)
") or die $dbh->errstr;

my $total_count = 0;

city:
for my $city (sort keys %cities) {
    my $url  = $cities{$city};
    my $mech = WWW::Mechanize->new();

    eval { $mech->get($url); };
    if ($@) {
        print "Error connecting to $url. Skipping...\n";
        next city;
    }

    my $tree
        = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));
    my @detail_divs = $tree->look_down(
        _tag  => 'div',
        class => 'second-column-container  table-cell'
    );
    my @price_divs = $tree->look_down(
        _tag  => 'div',
        class => 'third-column-container table-cell'
    );
    my @time_divs = $tree->look_down(
        _tag  => 'div',
        class => 'fourth-column-container table-cell'
    );
    print scalar @detail_divs . "\n";
    print scalar @price_divs . "\n";
    print scalar @time_divs . "\n";
    #exit;

    my $count = 0;
    ad:
    for my $div (@detail_divs) {
        my $a        = $div->look_down(_tag => 'a');
        my $link     = $a->attr('href');
        my $title    = $a->as_trimmed_text;
        my $summary  = $div->look_down(_tag => 'div', class => 'c-4')
            ->as_trimmed_text;
        my $details  = $div->look_down(
            _tag  => 'span',
            class => 'itemlistinginfo clearfix'
        )->as_trimmed_text;
        my @details  = map { trim($_) } split /\|/, $details;
        my $type     = pop @details;
        my $locality = pop @details;
        #my $locality = join ', ', @details;
        my $price    = $price_divs[$count]->as_trimmed_text;
        my $time     = $time_divs[$count]->as_trimmed_text;

        print "title: $title\n";
        print "summary: $summary\n";
        print "type: $type\n";
        print "locality: $locality\n";
        print "price: $price\n";
        print "time: $time\n";
        print "link: $link\n";
    
        $count++;
        print "count: $count\n\n";

        $sth->execute($city, $title, $type, $summary, $locality, $price,
            $time, $link) or next ad;

        $total_count++;
        print "total count: $total_count\n\n";
    }
}

sub trim {
    my $string = shift;
    $string    =~ s/^\s+|\s+$//g;
    return $string;
}

sub db_connect {
    my $self = shift;

    my $host     = 'localhost';
    my $db       = $conf->{db}{name};
    my $username = $conf->{db}{username};
    my $password = $conf->{db}{password};

    my $dbh = DBI->connect("DBI:mysql:$db:$host", $username, $password)
        or die "Connection Failed $DBI::errstr";
    return $dbh;
}