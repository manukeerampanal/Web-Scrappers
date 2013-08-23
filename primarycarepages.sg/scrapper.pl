#!/usr/bin/perl

no warnings;
use strict;

use Data::Dumper;
use Encode;
use HTML::TreeBuilder;
use WWW::Mechanize;

my %searches = (
    1 => {
        url => 'http://apps.primarycarepages.sg/directory/searchGP.aspx',
        specialty => 'GP',
        end_page => 69,
    },
    2 => {
        url => 'http://apps.primarycarepages.sg/directory/searchSpecialist.aspx',
        specialty => 'Specialist',
        end_page => 131,
    },
    3 => {
        url => 'http://apps.primarycarepages.sg/directory/searchPharmacist.aspx',
        specialty => 'Pharmacist',
        end_page => 63,
    },
    4 => {
        url => 'http://apps.primarycarepages.sg/directory/searchDentist.aspx',
        specialty => 'Dentist',
        end_page => 61,
    },
    5 => {
        url => 'http://apps.primarycarepages.sg/directory/searchTCM.aspx',
        specialty => 'TCM',
        end_page => 89,
    },
);

my $mech = WWW::Mechanize->new();

unless (-e './data/data.csv') {
    open (CSV, '>', './data/data.csv') || die $!;
    print CSV qq{"Name","Primary Clinic","Address Line 1","Address Line 2","Address Line 3","Tel No","Fax No","Website","Specialty"\n};
    close CSV;
}

open (CSV, '>>', './data/data.csv') || die $!;

for my $search (sort {$a <=> $b} keys %searches) {
    my $base_url = $searches{$search}{url};
    my $Specialty = $searches{$search}{specialty};
    my $end_page = $searches{$search}{end_page};

    for my $page (1 .. $end_page) {
        my $scrap_url = $base_url;
        $scrap_url .= "?pgno=$page" if $page > 1;
        print "url: $scrap_url\n";
        print "page: $page\n";

        eval {
            $mech->get($scrap_url);
        };

        if ($@) {
            print "Error connecting to URL $scrap_url. Exitting...\n";
            last;
        }

        my @links = $mech->find_all_links(url_regex => qr/detail.aspx/);

        print 'items: ' . scalar @links . "\n";
        next unless @links;

        my $count = 0;
        for my $link (@links) {
            my $url = $link->url_abs();
            eval {
                $mech->get($url);
            };

            if ($@) {
                print "Error connecting to URL $link. Exitting...\n";
                last;
            }

            my $tree = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));

            $count++;
            print "count: $count\n";

            my $Name = $tree->look_down(_tag => 'div', class => 'memDetName')->as_trimmed_text;

            my @details = $tree->look_down(_tag => 'span', class => 'memDet_info');

            my $Primary_Clinic = $details[0]->as_trimmed_text;

            my $Address = $details[1]->as_HTML;
            $Address =~ s/<span class="memDet_info">//;
            $Address =~ s/<\/span>//;
            my ($Address_Line_1, $Address_Line_2, $Address_Line_3) = split / <br \/>/, $Address;

            my $Tel_No = $details[2]->as_trimmed_text;
            my $Fax_No = $details[3]->as_trimmed_text;
            my $Website = $details[4]->as_trimmed_text;

            #$Primary_Clinic = $tree->look_down(_tag => 'div', id => 'ctl00_cphMain_ctlDirDetail_divPrimaryClinicName_HP')->look_down(_tag => 'span', class => 'memDet_info')->as_trimmed_text;
            #my $Address = $tree->look_down(_tag => 'div', id => 'ctl00_cphMain_ctlDirDetail_divPrimaryClinicAddress_HP')->look_down(_tag => 'span', class => 'memDet_info')->as_HTML;
            #$Tel_No = $tree->look_down(_tag => 'div', id => 'ctl00_cphMain_ctlDirDetail_divPrimaryTelNo_HP')->look_down(_tag => 'span', class => 'memDet_info')->as_trimmed_text;
            #$Fax_No = $tree->look_down(_tag => 'div', id => 'ctl00_cphMain_ctlDirDetail_divPrimaryFaxNo_HP')->look_down(_tag => 'span', class => 'memDet_info')->as_trimmed_text;
            #$Website = $tree->look_down(_tag => 'div', id => 'ctl00_cphMain_ctlDirDetail_divPrimaryWebsite_HP')->look_down(_tag => 'span', class => 'memDet_info')->as_trimmed_text;

            print "Name:$Name\n";
            print "Primary Clinic:$Primary_Clinic\n";
            print "Address:$Address\n";
            print "Address1:$Address_Line_1\n";
            print "Address2:$Address_Line_2\n";
            print "Address3:$Address_Line_3\n";
            print "Tel_No:$Tel_No\n";
            print "Fax_No:$Fax_No\n";
            print "Website:$Website\n";
            print "Specialty:$Specialty\n";
            print "\n\n";

            print CSV qq{"$Name","$Primary_Clinic","$Address_Line_1","$Address_Line_2","$Address_Line_3","$Tel_No","$Fax_No","$Website","$Specialty"\n};
        }
    }
}

close CSV;
