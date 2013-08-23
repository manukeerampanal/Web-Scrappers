#!/usr/bin/perl

no warnings;
use strict;

use Data::Dumper;
use Encode;
use HTML::TreeBuilder;
use WWW::Mechanize;

my $base_url = 'http://www.lats.org/directory.php';

my $mech = WWW::Mechanize->new();

open (CSV, '>>', 'data.csv') || die $!;

my $total_count = 0;

for my $page (1 .. 60) {
    my $count = 0;

    my $url = $base_url;
    $url .= "?pagina=$page" if $page > 1;
    print "url: $url\n";

    eval {
        $mech->get($url);
    };

    if ($@) {
        print "Error connecting to url $url. Skipping...\n";
        next;
    }

    my $tree = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));
    my $div  = $tree->look_down(_tag => 'div', class => 'txt-direct');

    my @ps = $div->look_down(_tag => 'p');
    print scalar @ps . "\n";
    for my $p (@ps) {
        $count++;
        $total_count++;

        #my @children = $p->content_list;
        #print "@children\n";
        #exit;

        #print Dumper $p->content_list();
        #exit;

        #print Dumper $p;
        #print keys %{$p};
        my $content = $p->as_HTML;
        my @lines = split /<br \/>/, $content;
        print scalar @lines;
        print "\n";
        #print "@lines\n";
        for (@lines) {
            $_ =~ s/<.+?>//g;
            $_ = trim($_);
        }
        #$lines[3] = encode("utf8", $lines[3]);
        #$lines[3] = decode_utf8($lines[3]);
        #print "$lines[0]\n";
        #print "$lines[1]\n";
        #print "$lines[2]\n";
        #print "$lines[3]\n";
        #print "$lines[4]\n";
        #print "$lines[5]\n";
        #print "$lines[6]\n";
        #print "$lines[7]\n";
        #print $p->as_HTML;

        my ($surname, $rem) = split /,/, $lines[0];
        my ($forename, $type, $since) = split /-/, $rem;

        #my ($name, $type, $since) = split /-/, $lines[0];
        #$name  = trim($name);
        $type  = trim($type);
        $since = trim($since);

        #my ($surname, $forename) = split /,/, $name;
        $surname  = trim($surname);
        $forename = trim($forename);

        #print CSV qq{$surname,$forename,$type,$since,};
        print CSV qq{$page\t$count\t$total_count\t};
        print CSV qq{$surname\t$forename\t$type\t$since\t};
        #print CSV qq{$lines[$_],} for 1 .. 7;
        print CSV qq{$lines[$_]\t} for 1 .. $#lines;
        print CSV "\n";

        #print $p->as_trimmed_text;
        print "\n";
        print "\n";
        #exit;
        #print Dumper @{$p->{_content}};
        #exit;
        #my @brs = $p->look_down(_tag => 'br');
        #print scalar @brs . "\n";
        #print Dumper $brs[1]->as_trimmed_text;
        #exit;
    }
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
