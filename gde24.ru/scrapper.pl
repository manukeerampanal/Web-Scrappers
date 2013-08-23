#!/usr/bin/perl

no warnings;
use strict;

use Data::Dumper;
use Encode;
use HTML::TreeBuilder;
use WWW::Mechanize;

my ($scrap_url, $start) = @ARGV;
$scrap_url ||= 'http://gde24.ru/company/result/AwDh7uv87ej24AAEAAA-B/';
$start ||= 1;
$start--;

my $mech = WWW::Mechanize->new();

open (CSV, '>>', 'data.csv') || die $!;

my $first_page = 0;

while ($scrap_url) {
    $start = 0 if $first_page;
    $first_page++;

    print "page_url: $scrap_url\n";

    eval {
        $mech->get($scrap_url);
    };

    if ($@) {
        print "Error connecting to scrap page_url $scrap_url. Exitting...\n";
        print "perl scrapper.pl $scrap_url";
        if ($start) {
            my $restart = $start + 1;
            print " $restart";
        }
        print "\n\n";
        exit;
    }

    my $root = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));
    my $page = ($root->look_down(_tag => 'td', class => 'pagelist'))[0]->look_down(_tag => 'b')->as_trimmed_text;
    print "page: $page\n";

    my $next_page = $page + 1;
    my $next_url = $mech->find_link(text => $next_page, url_regex => qr/company\/result/);
    if ($next_url) {
        $next_url = $next_url->url_abs();
    }
    else {
        $next_url = $mech->find_link(text => '...', url_regex => qr/company\/result/);
        $next_url = $next_url->url_abs() if $next_url;
    }
    print "next_page_url: $next_url\n";

    my @links = $mech->find_all_links(class => 'head');
    print 'items: ' . scalar @links . "\n";
    next unless @links;

    for ($start .. $#links) {
        print "page_url: $scrap_url\n";

        my $count = $_ + 1;
        print "page: $page, start: $start, count: $count\n";

        my $link = $links[$_];
        my $url = $link->url_abs();
        print "item_url: $url\n";

        eval {
            $mech->get($url);
        };

        if ($@) {
            print "Error connecting to item_url $url. Exitting...\n";
            print "perl scrapper.pl $scrap_url $count\n\n";
            exit;
        }

        my $tree = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));

        my $name = $tree->look_down(_tag => 'td', class => 'name')->as_trimmed_text;
        my ($name1, $name2);
        if ($name =~ /\(/) {
            ($name1, $name2) = $name =~ m/(.+)(\(.*)/;
        }
        else {
            $name1 = $name;
        }
        print "name: $name, name1: $name1, name2: $name2\n";
        #$name2 =~ s/\"/\\\"/g;

        my $padding23 = ($tree->look_down(_tag => 'div', class => 'padding23'))[0];

        my ($city, $district);
        my @a = $padding23->look_down(_tag => 'a');
        if (@a) {
            $city = $a[0]->as_trimmed_text;
            $city = '' if $city =~ /\(\d+\)/;
            if ($a[1]) {
                    my $district = $a[1]->as_trimmed_text;
                    $district = '' if $district =~ /\(\d+\)/;
            }
        }
        print "city: $city, district: $district\n";

        my $updated_date = $tree->look_down(_tag => 'td', class => 'option')->as_trimmed_text;
        print "updated_date: $updated_date\n";

        my ($add1_post_code, $add1_city, $add1_street, $legal_post_code, $legal_city, $legal_street);
        my $inc = 1;
        my @info = $tree->look_down(_tag => 'td', class => 'info');
        if (@info) {
            my @div = $info[0]->look_down(_tag => 'div');
            if (@div) {
                my $add = $div[0]->as_trimmed_text;
                print "add: $add\n";
                #my @add = map { trim($_) } split /,/, $add;
                my @add = split /, /, $add;
                ($add1_post_code) = $add[0] =~ m/(\d+)/;
                $add1_city = $add[1];
                $add1_street = "$add[2], $add[3]";
                print "add1_post_code: $add1_post_code, add1_city: $add1_city, add1_street: $add1_street\n";

                $inc = 2;

                if ($div[1]) {
                    $inc = 3;

                    my $legal = $div[1]->as_trimmed_text;
                    print "legal: $legal\n";
                    my @legal = split /, /, $legal;
                    ($legal_post_code) = $legal[0] =~ m/(\d+)/;
                    $legal_city = $legal[1];
                    $legal_street = "$legal[2], $legal[3]";
                }
            }
        }

        print "legal_post_code: $legal_post_code, legal_city: $legal_city, legal_street: $legal_street\n";

        my @total_phones = $padding23->look_down(_tag => 'img', src => '../../../App_Themes/Default/img/ic_phone.gif');
        print "phones count: " . scalar @total_phones . ", ";
        my @total_faxes = $padding23->look_down(_tag => 'img', src => '../../../App_Themes/Default/img/ic_fax.gif');
        print "faxes count: " . scalar @total_faxes . ", ";
        my @total_emails = $padding23->look_down(_tag => 'img', src => '../../../App_Themes/Default/img/ic_email.gif');
        print "emails count: " . scalar @total_emails . ", ";
        my @total_webs = $padding23->look_down(_tag => 'img', src => '../../../App_Themes/Default/img/ic_web.gif');
        print "webs count: " . scalar @total_webs . "\n";

        my @div1 = $padding23->look_down(_tag => 'div');
        #print "scalar: " . scalar @div1 . "\n";
        #for (4 .. @div1) {
        #    print $div1[$_]->as_trimmed_text . "\n";
        #}

        my @phones;
        for (1 .. @total_phones) {
            $_ += $inc;
            push @phones, $div1[$_]->as_trimmed_text;
        }
        print "phones: @phones\n";

        my @faxes;
        for (1 .. @total_faxes) {
            $_ += @total_phones + $inc;
            push @faxes, $div1[$_]->as_trimmed_text;
        }
        print "faxes: @faxes\n";

        my @emails;
        for (1 .. @total_emails) {
            $_ += @total_phones + @total_faxes + $inc;
            push @emails, $div1[$_]->as_trimmed_text;
        }
        print "emails: @emails\n";

        my @webs;
        for (1 .. @total_webs) {
            $_ += @total_phones + @total_emails + @total_faxes + $inc;
            push @webs, $div1[$_]->as_trimmed_text;
        }
        print "webs: @webs\n";

        #print $div1[-2]->as_trimmed_text . "\n";
        #print $div1[-1]->as_trimmed_text . "\n";

        my ($license_no) = $div1[-2]->as_trimmed_text =~ m/:\s*(.+)/;
        my ($institute_type) = $div1[-1]->as_trimmed_text =~ m/:\s*(.+)/;
        #my $institute_type = $padding23->look_down(_tag => 'li', class => 'image')->as_trimmed_text;
        print "license_no: $license_no, institute_type: $institute_type\n";

        print CSV qq{~$name1~,~$name2~,~$city~,~$district~,~$updated_date~,~$add1_post_code~,~$add1_city~,~$add1_street~,~$legal_post_code~,~$legal_city~,~$legal_street~,};
        print CSV qq{~$phones[$_]~,} for 0 .. 10;
        print CSV qq{~$faxes[0]~,~$faxes[1]~,~$emails[0]~,~$emails[1]~,~$webs[0]~,~$webs[1]~,~$license_no~,~$institute_type~,~$url~\n};

        print "\n";
    }

    $scrap_url = $next_url;
}

END {
    close CSV;
}

sub trim($) {
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}
