#!/usr/bin/perl

use lib "/root/Real-Estate/lib";
use strict;

use Database;

use Parallel::ForkManager;

my $db = Database->new;

# Backup old ads and delete thereafter
my $sth = $db->{dbh}->prepare("
    INSERT INTO
        ad_backup
        (ad_id, city, source, title, type, summary, locality, price, time, link, contact_name, contact_number, added_date)
    SELECT
        id, city, source, title, type, summary, locality, price, time, link, contact_name, contact_number, added_date
    FROM
        ad
    WHERE
        DATEDIFF(CURDATE(), added_date) >= 30
") or warn $db->{dbh}->errstr;
$sth->execute() or warn $db->{dbh}->errstr;

$sth = $db->{dbh}->prepare("
    DELETE FROM
        ad
    WHERE
        DATEDIFF(CURDATE(), added_date) >= 30
") or warn $db->{dbh}->errstr;
$sth->execute() or warn $db->{dbh}->errstr;

my @scripts = qw(
    /root/Real-Estate/OLX/All.pl
    /root/Real-Estate/99Acres/All.pl
    /root/Real-Estate/IndiaProperty/All.pl
    /root/Real-Estate/MagicBricks/All.pl
    /root/Real-Estate/Click/All.pl
    /root/Real-Estate/Quikr/All.pl
);

my $pm = Parallel::ForkManager->new(scalar @scripts);

for my $script (@scripts) {
    $pm->start and next;
    `/usr/bin/perl $script`;
    $pm->finish;
}
