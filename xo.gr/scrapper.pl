#!/usr/bin/perl

no warnings;
use strict;

#use Data::Dumper;
use Encode;
use HTML::TreeBuilder;
use POSIX;
use WWW::Mechanize;

my ($category, $start_page, $total_records, $location) = @ARGV;

my $page_records = 20;
$total_records ||= 600;
my $end_page = ceil ($total_records / $page_records);
$start_page ||= 1;

my $base_url = 'http://www.xo.gr/search/?what=%CE%B3%CE%B9%CE%B1%CF%84%CF%81%CF%8C%CF%82';
$base_url .= "&catFlt=$category" if $category;
$base_url .= "&locId=$location" if $location;

my $mech = WWW::Mechanize->new();

unless (-e 'data.csv') {
    open (CSV, '>', 'data.csv') || die $!;
    print CSV qq{"Name","Address","City/area","Telephone","Fax","Mobile","Category","Additional information","Email","Website"\n};
    close CSV;
}

open (CSV, '>>', 'data.csv') || die $!;

for my $page ($start_page .. $end_page) {
    my $scrap_url = $base_url;
    $scrap_url .= "&page=$page" if $page > 1;
    print "url: $scrap_url\n";
    print "page: $page\n";

    eval {
        $mech->get($scrap_url);
    };

    if ($@) {
        print "Error connecting to URL $scrap_url. Exitting...\n";
        last;
    }

    my $tree  = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));
    my @items = $tree->look_down(_tag => 'div', class => 'top_sponsor');

    print 'items: ' . scalar @items . "\n";
    print "last page: $end_page\n\n";
    last unless @items;

    my $count = 0;
    for my $item (@items) {
        $count++;
        print "count: $count\n";

        my $Name    = $item->look_down(_tag => 'a', class => 'customer_name')->as_trimmed_text;
        my $Address = $item->look_down(_tag => 'input', type => 'hidden')->{value};

        my $nowrap;
        my @nowrap  = $item->look_down(_tag => 'span', class => 'nowrap');
        if ($nowrap[2]) {
            $nowrap = $nowrap[2];
        }
        else {
            $nowrap = $nowrap[1];
        }
        my $City = '';
        $City = $nowrap->as_trimmed_text if $nowrap;

        my $Contact_div = $item->look_down(_tag => 'div', class => 'profile_contactLine');
        my $Contact = '';
        $Contact = $Contact_div->as_trimmed_text if $Contact_div;

        my @contacts = split /-/, $Contact;

        my ($Telephone, $Fax, $Mobile);
        ($Telephone) = $contacts[0] =~ m/(\d+)/ if $contacts[0];

        if ($contacts[1]) {
            if ($contacts[1] =~ /fax/) {
                ($Fax) = $contacts[1] =~ m/(\d+)/;
            }
            else {
                ($Mobile) = $contacts[1] =~ m/(\d+)/;
            }
        }

        if ($contacts[2]) {
            if ($contacts[2] =~ /fax/) {
                ($Fax) = $contacts[2] =~ m/(\d+)/;
            }
            else {
                ($Mobile) = $contacts[2] =~ m/(\d+)/;
            }
        }

        my $Category   = $item->look_down(_tag => 'p', class => 'category_lbl')->as_trimmed_text;

        my $Addl_info  = '';
        my $ul         = $item->look_down(_tag => 'ul', class => 'lists');
        if ($ul) {
            my @lis = $ul->look_down(_tag => 'li');
            if (@lis) {
                $Addl_info .= $_->as_trimmed_text . ', ' for @lis;
                $Addl_info =~ s/, $//;
            }
            else {
                $Addl_info = $ul->as_trimmed_text;
            }
        }

        my ($Email, $Website);
        $ul = $item->look_down(_tag => 'ul', class => 'links_list');
        if ($ul) {
            my @lis = $ul->look_down(_tag => 'li');
            for (@lis) {
                if ($_->as_trimmed_text eq 'Web Site') {
                    my $a = $_->look_down(_tag => 'a');
                    $Website = $a->{href};
                }
                elsif ($_->as_trimmed_text eq 'E-mail') {
                    my $a = $_->look_down(_tag => 'a');
                    ($Email = $a->{href}) =~ s/^mailto://;
                }
            }
        }

        print "Name:$Name\n";
        print "Address:$Address\n";
        print "City:$City\n";
        print "Telephone:$Telephone\n";
        print "Fax:$Fax\n";
        print "Mobile:$Mobile\n";
        print "Category:$Category\n";
        print "Addl_info:$Addl_info\n";
        print "Email:$Email\n";
        print "Website:$Website\n";
        print "\n\n";

        print CSV qq{"$Name","$Address","$City","$Telephone","$Fax","$Mobile","$Category","$Addl_info","$Email","$Website"\n};
    }
}

close CSV;
