#!/usr/bin/perl

no warnings;
use strict;

use Data::Dumper;
use Encode;
use HTML::TreeBuilder;
use WWW::Mechanize;

my ($region, $start) = @ARGV;

if (!$region) {
    print "Enter region";
    exit;
}
elsif ($region > 77) {
    print "There are only 77 regions";
    exit;
}
elsif (!$start) {
    print "Enter start record";
    exit;
}

$region--;
$start--;

my $base_url = 'http://www.med-otzyv.ru/kliniks';

my @regions = qw(38-moskovskaya 39-belgorodskaya 40-bryanskaya 41-vladimirskaya 42-voronezhskaya 43-ivanovskaya 44-kaluzhskaya 45-kostromskaya 46-kurskaya 47-lipeckaya 48-orlovskaya 49-ryazanskaya 50-smolenskaya 51-tambovskaya 52-tverskaya 53-tulskaya 54-yaroslavskaya 55-sankt-peterburg 56-arxangelskaya 57-vologodskaya 58-kaliningradskaya 59-leningradskaya 60-murmanskaya 61-novgorodskaya 62-pskovskaya 63-respublika-kareliya 64-respublika-komi 65-kurganskaya 66-sverdlovskaya 67-tyumenskaya 68-chelyabinskaya 69-altajskij-kraj 70-irkutskaya 71-kemerovskaya 72-krasnoyarskij-kraj 73-novosibirskaya 74-omskaya 75-respublika-altaj 76-respublika-buryatiya 77-respublika-tyva 78-respublika-xakasiya 79-tomskaya 80-chitinskaya 81-kirovskaya 82-nizhegorodskaya 83-orenburgskaya 84-penzenskaya 85-permskaya 86-respublika-bashkortostan 87-respublika-marij-yel 88-respublika-mordoviya 89-respublika-tatarstan 90-samarskaya 91-saratovskaya 92-udmurtskaya-respublika 93-ulyanovskaya 94-chuvashskaya-respublika 95-astraxanskaya 96-volgogradskaya 97-kabardino-balkarskaya-respublika 98-karachaevo-cherkesskaya-respublika 99-krasnodarskij-kraj 100-respublika-adygeya 101-respublika-dagestan 102-respublika-ingushetiya 103-respublika-kalmykiya 104-respublika-severnaya-osetiya-alaniya 105-rostovskaya 106-stavropolskij-kraj 107-chechenskaya-respublika-ichkeriya 108-amurskaya 109-evrejskaya-avtonomnaya 110-magadanskaya 111-primorskij-kraj 112-respublika-saxa-yakutiya 113-saxalinskaya 114-xabarovskij-kraj);

#print scalar @regions . "\n";
#print "region: $region\n";
$region = $regions[$region];
#print "region: $region\n";
#exit;

my $mech = WWW::Mechanize->new();

open (CSV, '>>', 'data.csv') || die $!;

my $scrap_url = "$base_url/$region?limit=0";
print "region url: $scrap_url\n";

eval {
    $mech->get($scrap_url);
};

if ($@) {
    print "Error connecting to region url $scrap_url. Exitting...\n";
    exit;
}

#my @links = $mech->find_all_links(url_regex => qr/kliniks/);
my @links = $mech->find_all_links(url_regex => qr/kliniks\/$region/);

print 'Total records in this region: ' . scalar @links . "\n";
unless (@links) {
    print "Exitting... Please enter the captcha\n";
    exit;
}

#for my $link (@links) {
for ($start .. $#links) {
    my $link = $links[$_];
    my $url = $link->url_abs();
    print "record url: $url\n\n";

    my $count = $_ + 1;
    print "count: $count\n\n";

    my $attrs = $link->attrs();
    my $class = $attrs->{class};
    #print "class: $class\n";
    next if $class eq 'jcl_objtitle';

    sleep 3;

    eval {
        $mech->get($url);
    };

    if ($@) {
        print "Error connecting to record url $link. Exitting...\n";
        exit;
    }

    my $tree = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));

    my @pathway = $tree->look_down(_tag => 'a', class => 'pathway');
    if (!@pathway) {
        print "Exitting... Please enter the captcha\n";
        exit;
    }

    my $Region = $pathway[2]->as_trimmed_text;
    print "Region: $Region\n";

    #my $article = $tree->look_down(_tag => 'div', class => 'article')->as_trimmed_text;
    my $article = $tree->look_down(_tag => 'div', class => 'article');

    my $Headline = $article->look_down(_tag => 'h1')->as_trimmed_text;

    my @fonts = $article->look_down(_tag => 'font');
    my $h1 = $fonts[0]->as_trimmed_text;
    my $h2 = $fonts[1]->as_trimmed_text;
    my $h3 = $fonts[2]->as_trimmed_text;
    my $h4 = $fonts[3]->as_trimmed_text;
    my $h5 = $fonts[4]->as_trimmed_text;
    my $h6 = $fonts[5]->as_trimmed_text;

    $article = $article->as_trimmed_text;

    my ($address, $Chief_physician, $phone, $fax, $Official_Website, $information) = $article =~ m/$h1(.*)$h2(.*)$h3(.*)$h4(.*)$h5(.*)$h6(.*)/g;

    $address = trim($address);
    $Chief_physician = trim($Chief_physician);
    $phone = trim($phone);
    $fax = trim($fax);
    $Official_Website = trim($Official_Website);
    $information = trim($information);

    print "Headline: $Headline\n";
    print "address: $address\n";
    print "Chief_physician: $Chief_physician\n";
    print "phone: $phone\n";
    print "fax: $fax\n";
    print "Official_Website: $Official_Website\n";
    print "information: $information\n\n";

    print CSV qq{"$Headline","$address","$Chief_physician","$phone","$fax","$Official_Website","$information","$Region","$url"\n};
}

print "Region finished. Go with next region.\n";

END {
    close CSV;
}

sub trim($) {
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}
