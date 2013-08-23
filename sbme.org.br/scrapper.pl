#!/usr/bin/perl

no warnings;
use strict;

use Data::Dumper;
use Encode;
use HTML::TreeBuilder;
use WWW::Mechanize;

my $base_url = 'http://www.sbme.org.br/portal/associados-resultado.shtml';

my $mech = WWW::Mechanize->new();

eval {
    $mech->get($base_url);
};

if ($@) {
    print "Error connecting to scrap page_url $base_url. Exitting...\n";
    exit;
}

my @links = $mech->find_all_links(url_regex => qr~http://www.sbme.org.br/portal/detalhes/\d+/associados_detalhes.shtml~);

open (CSV, '>>', 'data.csv') || die $!;

print 'items: ' . scalar @links . "\n\n";
exit unless @links;

my $count = 0;
for my $link (@links) {
    my $url = $link->url_abs();
    print "url: $url\n";

    eval {
        $mech->get($url);
    };

    if ($@) {
        print "Error connecting to url $url. Exitting...\n";
        next;
    }

    my $tree = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));

    my @trs    = $tree->look_down(_tag => 'tr', class => 'zebraLista');
    my ($name)   = $trs[0]->as_trimmed_text =~ m/:(.+)/;
    my ($street) = $trs[1]->as_trimmed_text =~ m/:(.+)/;
    my ($bairro) = $trs[2]->as_trimmed_text =~ m/:(.+)/;
    my ($city)   = $trs[3]->as_trimmed_text =~ m/:(.+)/;
    my ($uf)     = $trs[4]->as_trimmed_text =~ m/:(.+)/;
    my ($phone)  = $trs[5]->as_trimmed_text =~ m/:(.+)/;
    my ($email)  = $trs[6]->as_trimmed_text =~ m/:(.+)/;

    print "name: $name\n";
    print "street: $street\n";
    print "bairro: $bairro\n";
    print "city: $city\n";
    print "uf: $uf\n";
    print "phone: $phone\n";
    print "email: $email\n";

    $count++;
    print "count: $count\n\n";
    #exit;

    print CSV qq{"$name","$street","$bairro","$city","$uf","$phone","$email","$url"\n};
}

END {
    close CSV;
}
