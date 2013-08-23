#!/usr/bin/perl

no warnings;
use strict;

use Data::Dumper;
use Encode;
use HTML::TreeBuilder;
use WWW::Mechanize;

my $select_group = $ARGV[0];

my @groups = ('15,Alergolodzy', '9,Anestezjolodzy', '1,Chirurdzy', '7,Dermatolodzy', '30,Diabetolodzy', '32,Endokrynologia', '12,Ginekolodzy', '33,Hematolodzy', '17,Internisci', '20,Kardiolodzy', '23,Laryngolodzy', '27,Logopedzy', '24,Medycyna estetyczna', '13,Medycyny pracy', '25,Medycyny sportowej', '21,Neurolodzy', '19,Okulisci', '6,Onkolodzy', '28,Optycy', '14,Ortodonci', '8,Ortopedzi', '16,Pediatrzy', '26,Psychiatrzy', '18,Psycholodzy', '22,Rehabilitacja', '29,Reumatolodzy', '3,Stomatolodzy', '10,Traumatolodzy', '4,Urolodzy');
@groups = ($groups[$select_group]);

my @regions = ('4,Alergolodzy,Dolnoslaskie', '9,Alergolodzy,Kujawsko-Pomorskie', '11,Alergolodzy,Lubelskie', '12,Alergolodzy,Lubuskie', '7,Alergolodzy,Lodzkie', '5,Alergolodzy,Malopolskie', '2,Alergolodzy,Mazowieckie', '13,Alergolodzy,Opolskie', '14,Alergolodzy,Podkarpackie', '15,Alergolodzy,Podlaskie', '8,Alergolodzy,Pomorskie', '3,Alergolodzy,Slaskie', '16,Alergolodzy,Swietokrzyskie', '17,Alergolodzy,Warminsko-Mazurskie', '1,Alergolodzy,Wielkopolskie', '6,Alergolodzy,Zachodniopomorskie');

my $mech = WWW::Mechanize->new();

#unless (-e 'data.csv') {
#    open (CSV, '>', 'data.csv') || die $!;
#    print CSV qq{"Headline","Slowa kluczowe","Nazwa firmy","Imi? i Nazwisko (first part = first name)","Imi? i Nazwisko (second part = last name)","Specjalizacje","Miejscowo??","Adres","Strona WWW","Telefon"\n};
#    close CSV;
#}

open (CSV, '>>', "$select_group.csv") || die $!;

for my $group (@groups) {
    print "group: $group\n";
    for my $region (@regions) {
        print "region: $region\n";

        my $scrap_url = "http://medycznie.info/?group_id=$group&region_id=$region";
        print "scrap_url: $scrap_url\n";

        eval {
            $mech->get($scrap_url);
        };

        if ($@) {
            print "Error connecting to URL $scrap_url. Exitting...\n";
            last;
        }

        my $tree = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));
        my $select = $tree->look_down(_tag => 'select', name => 'miasto');
        #my @cities = $select->as_HTML =~ m/&#39;(.+?)&#39;/g;
        my @cities = $select->as_HTML =~ m/valute="(.+?)"/g;
        print 'cities: ' . scalar @cities . "\n";

        for my $city (@cities) {
            print "city: $city\n";

            eval {
                $mech->get("$scrap_url&city=$city");
            };

            if ($@) {
                print "Error connecting to URL $scrap_url. Exitting...\n";
                last;
            }

            my @links = $mech->find_all_links(url_regex => qr/doctor_id/);

            print 'items: ' . scalar @links . "\n";
            next unless @links;

            my $count = 0;
            for my $link (@links) {
                my $url = $link->url_abs();
                print "url: $url\n";

                eval {
                    $mech->get($url);
                };

                if ($@) {
                    print "Error connecting to URL $link. Exitting...\n";
                    last;
                }

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

                print CSV qq{"$Headline","$Keywords","$Company","$first_name","$last_name","$Specialties","$Location","$Address","$Website","$Telephone"\n};
                #exit;
            }
        }
    }
}

END {
    close CSV;
}
