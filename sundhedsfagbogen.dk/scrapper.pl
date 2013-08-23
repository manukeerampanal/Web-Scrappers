#!/usr/bin/perl

no warnings;
use strict;
use Data::Dumper;
use Encode;
use HTML::TreeBuilder;
use WWW::Mechanize;

#local $\ = "\n";

my $mech = WWW::Mechanize->new();

my $base_url = 'http://www.sundhedsfagbogen.dk/kategori/1/L%C3%A6ger.htm';

eval {
    $mech->get($base_url);
};

if ($@) {
    print "Error connecting to URL $base_url. Exiting...\n";
    exit;
}

#my @categories = $mech->find_all_links(url_regex => qr/\/kategorier-/);
#print scalar @categories;

my @allLinks = $mech->find_all_links(class => 'categorySub');
print scalar @allLinks . "\n";

for my $link (@allLinks) {
    my ($pages, $page) = (0, 1);
    my $scrap_url = $link->url_abs();
    print "scrap_url: $scrap_url\n";
    my ($q) = $scrap_url =~ m/q\/(\d+)\//;
    print "q: $q\n";

    do {
        print "page: $page\n";

        $scrap_url = "http://www.sundhedsfagbogen.dk/q/$q/listevisning.htm?page=$page" if $page > 1;

        eval {
            $mech->get($scrap_url);
        };

        if ($@) {
            print "Error connecting to URL $scrap_url. Skipping...\n";
            next;
        }

        my $root = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));
        my $count_span = $root->look_down(_tag => 'span', id => 'ctl00_ContentMain_ucCategory_ucSearchResult_ucPagerTop_lblDisplays');
        next unless $count_span;
        unless ($pages) {
            if ($count_span) {
                print $count_span->as_trimmed_text . "\n";
                ($pages) = $count_span->as_trimmed_text =~ m/\((\d+)/;
            }
        }
        print "pages: $pages\n";

        if ($pages) {
            my $main_table = $root->look_down(_tag => 'table', id => 'ctl00_ContentMain_ucCategory_ucSearchResult_dlistCustomer');
            my @tables = $main_table->look_down(_tag => 'table', width => '100%',  'cellpadding' => 0, 'cellspacing' => 0, 'border' => 0, 'align' => 'left');
            print "tables: " . scalar @tables . "\n";
        }

        $page++;
    } while ($pages > 1 && $page <= $pages);

    #exit;
}
exit;

my $total_records = '26158';
my $page_records  = 20;
my $total_pages   = int ($total_records / $page_records);

#open (CSV, '>', 'data.csv') || die $!;
#print CSV qq{"Name","Address","City/area","Telephone","Fax","Mobile","Category","Additional information","Email","Website"\n};
open (CSV, '>>', 'data.csv') || die $!;

#for my $page (0, 2 .. 337) {
for my $page (21 .. 337) {
    my $scrap_url = $base_url;
    $scrap_url .= "&page=$page" if $page;
    print "url: $scrap_url\n";

    eval {
        $mech->get($scrap_url);
    };

    if ($@) {
        print "Error connecting to URL $scrap_url. Skipping...\n";
        next;
    }

    my $tree         = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));
    my @items        = $tree->look_down(_tag => 'div', class => 'top_sponsor');

    print "page: $page\n";
    print 'items: ' . scalar @items . "\n";
    #next unless @items;
    close_file() unless @items;

    my $count = 0;
    for my $item (@items) {
        $count++;
        print "count: $count\n";
        my $Name       = $item->look_down(_tag => 'a', class => 'customer_name')->as_trimmed_text;
        my $Address    = $item->look_down(_tag => 'input', type => 'hidden')->{value};

        my $nowrap;
        my @nowrap     = $item->look_down(_tag => 'span', class => 'nowrap');
        if ($nowrap[2]) {
            $nowrap = $nowrap[2];
        }
        else {
            $nowrap = $nowrap[1];
        }
        my $City       = $nowrap->as_trimmed_text;

        my $Contact    = $item->look_down(_tag => 'div', class => 'profile_contactLine')->as_trimmed_text;
        my @contacts   = split /-/, $Contact;

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
            my @lis    = $ul->look_down(_tag => 'li');
            if (@lis) {
                $Addl_info .= $_->as_trimmed_text . ', ' for @lis;
                $Addl_info =~ s/, $//;
            }
            else {
                $Addl_info = $ul->as_trimmed_text;
            }
        }

        my ($Email, $Website);
        $ul             = $item->look_down(_tag => 'ul', class => 'links_list');
        if ($ul) {
            my @lis    = $ul->look_down(_tag => 'li');
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

close_file();

sub close_file {
    close CSV;
    exit;
}