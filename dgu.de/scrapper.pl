#!/usr/bin/perl

no warnings;
use strict;

use Data::Dumper;
use Encode;
use HTML::TreeBuilder;
use WWW::Mechanize;

my $base_url = 'http://www.dgu.de';

my @groups = qw(410 417 418 416 419 406 407 422 421 420 408 409 412 413 414 411);

my $mech = WWW::Mechanize->new();


#unless (-e 'data.csv') {
#    open (CSV, '>', 'data.csv') || die $!;
#    print CSV qq{"Headline","Slowa kluczowe","Nazwa firmy","Imi? i Nazwisko (first part = first name)","Imi? i Nazwisko (second part = last name)","Specjalizacje","Miejscowo??","Adres","Strona WWW","Telefon"\n};
#    close CSV;
#}

#open (CSV, '>>', 'data.csv') || die $!;

for my $group (@groups) {
    print "group: $group\n";
    $mech->get("$base_url/index.php?id=$group");
    my $tree = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));
    my @maps = $tree->look_down(_tag => 'map');
    my @regions = $maps[1]->as_HTML =~ m/code=(\d+?)"/g;
    my @hrefs = $maps[1]->as_HTML =~ m/href="(.+?)"/g;
    print "@hrefs";

    for my $url (@hrefs) {
        print "url: $url\n";
        $url =~ s/amp;//;

        #my $scrap_url = "$base_url/index.php?id=$group&code=$region";
        my $scrap_url = "$base_url/$url";
        print "url: $scrap_url\n";

        eval {
            $mech->get($scrap_url);
        };

        if ($@) {
            print "Error connecting to URL $scrap_url. Exitting...\n";
            last;
        }

        my $tree = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));
        my @trs = $tree->look_down(_tag => 'tr', valign => 'top');
        print scalar @trs;
        exit;

        my $count = 0;

        my $tree = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));
        my $Inside = $tree->look_down(_tag => 'div', id => 'Inside');

        $count++;
        print "count: $count\n";

        my $Headline = $Inside->look_down(_tag => 'div', class => 'InsideCat')->as_trimmed_text;
        print "Headline: $Headline\n";

        my $Keywords = $Inside->look_down(_tag => 'div', style => 'width: 70%; padding-left: 10px;')->as_trimmed_text;
        $Keywords =~ s/^.+?: ?//;
        print "Keywords: $Keywords\n";

        my @details = $Inside->look_down(_tag => 'div', style => 'padding: 3px; font-weight: bold;');

        my $name = $details[0]->as_trimmed_text;
        my ($Company, $Name, $first_name, $last_name);
        if ($name =~ /Nazwa firmy:/) {
            ($Company = $name) =~ s/^.+?: ?//;
        }
        else {
            ($Name = $name) =~ s/^.+?: ?//;
            ($first_name, $last_name) = split / /, $Name;
        }
        print "Name: $Name ($first_name, $last_name)\n";
        print "Company: $Company\n";

        my $Specialties = $details[1]->as_trimmed_text;
        $Specialties =~ s/^.+?: ?//;
        print "Specialties: $Specialties\n";

        my $Location = $details[2]->as_trimmed_text;
        $Location =~ s/^.+?: ?//;
        print "Location: $Location\n";

        my $Address = $details[3]->as_trimmed_text;
        $Address =~ s/^.+?: ?//;
        print "Address: $Address\n";

        my $Website = $details[4]->as_trimmed_text;
        $Website =~ s/^.+?: ?//;
        print "Website: $Website\n";

        my $Telephone = $details[5]->as_trimmed_text;
        $Telephone =~ s/^.+?: ?//;
        print "Telephone: $Telephone\n";

        print "\n\n";

        #print CSV qq{"$Headline","$Keywords","$Company","$first_name","$last_name","$Specialties","$Location","$Address","$Website","$Telephone"\n};
    }
}

END {
    close CSV;
}
