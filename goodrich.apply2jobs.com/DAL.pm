package DAL;
use strict;

# Database Abstraction Layer #
# All Database Related Events Here #

use DBIx::Simple;
use HTML::Scrubber;

sub readConfig($);

#Start Here - REad CONFIG HERE
my $Config = readConfig("Config.ini");
my $dbi = "dbi:mysql:database=" . $Config->{DBCreds}->{DBName}. ";host=" . $Config->{DBCreds}->{DBHost};
my $db = DBIx::Simple->connect($dbi, $Config->{DBCreds}->{DBUser}, $Config->{DBCreds}->{DBPass});

#BEGIN
sub get_new_vacancy_id {
    my $last_id = $db->query("SELECT vac_ref from vacancy ORDER BY vac_ref DESC LIMIT 1")->list;
    return $last_id + 1;
}
#END

#BEGIN
sub read_advertiser_info(){
    my $info = $db->query("SELECT adv_tel,adv_cont_1,adv_title,adv_add1,adv_add2,adv_add3,adv_add4,adv_pcode,adv_email, adv_fax_1
                          from advertiser WHERE adv_ref = ? ORDER BY adv_ref DESC LIMIT 1",$Config->{Advertiser}->{ADREF})->array;
    return $info ;
}
#END

#BEGIN
sub max_duplicate_reached{
    my ($class, $count) = @_;
    return 1 if $count > $Config->{Limits}->{MAXDUPLICATE};
    return 0;
}
#END

#Check that we do not load vacancies more than once
sub check_scrape_vacancies {
    my ($class, $jobref) = @_;
    my $check = $db->query("SELECT 1 FROM scrape_vacancies WHERE sv_ref = ? AND sv_script = ?", $jobref,$Config->{Script}->{NAME})->list;
    return $check;
}
#END

#Record to Vacancy
sub insert_vacancy {
    my ($class, $data) = @_;

    RE_INSERT:
    my $vac_ref = get_new_vacancy_id();
    
    print "Vacancy ID ===> $vac_ref\n";
    #eval{
        $db->query("
            INSERT INTO vacancy
            (
                vac_ref,
                vac_cre_dte,
                vac_status,
                vac_job_title,
                vac_advertiser,
                vac_phone,
                vac_contact,
                vac_title,
                vac_dur_type,
                vac_flex,
                vac_fax,
                vac_add1,
                vac_add2,
                vac_add3,
                vac_add4,
                vac_pcode,
                vac_machine,
                vac_modified,
                vac_user,
                vac_text,
                vac_locn,
                vac_type,
                vac_email_sent,
                vac_board,
                vac_salary,
                vac_advjob,
                vac_effective,
                vac_email,
                vac_url,
                vac_jd,
                vac_lsource,
                vac_f_source,
                vac_f_sector,
                vac_f_sector2,
                vac_f_sector3,
                vac_country,
                vac_object,
                vac_date
             )
             VALUES
             (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,NOW())",
                $vac_ref,
                $data->{vac_cre_dte},
                $data->{vac_status},
                $data->{vac_job_title},
                $Config->{Advertiser}->{ADREF},
                $data->{vac_phone},
                $data->{vac_contact},
                $data->{vac_title},
                '',
                '',
                $data->{vac_fax},
                $data->{vac_add1},
                $data->{vac_add2},
                $data->{vac_add3},
                $data->{vac_add4},
                $data->{vac_pcode},
                $data->{vac_machine},
                $data->{Vac_cre_dte},
                $data->{vac_user},
                $data->{vac_text},
                $data->{vac_locn},
                $data->{vac_type},
                '',
                '',
                $data->{vac_salary},
                $data->{vac_advjob},
                $data->{vac_cre_dte},
                $data->{vac_email},
                $data->{vac_url},
                $data->{vac_jd},
                $data->{vac_lsource},
                $data->{vac_f_source},
                $Config->{Advertiser}->{SEC_1},
                $Config->{Advertiser}->{SEC_2},
                $Config->{Advertiser}->{SEC_3},
                $data->{vac_country},
                ''
        );
       
    if ($db->{success} eq 0) {
        print "Retrying Insert Vacancy....";
        goto RE_INSERT;
    }
    
    RE_INSERT_SCRAPE: 
        $db->query("INSERT INTO scrape_vacancies (sv_script, sv_ref, sv_date, sv_our_ref)
        VALUES (?, ?, CURRENT_DATE, ?) ",
        $Config->{Script}->{NAME}, $data->{sv_ref}, $vac_ref);
        
    if ($db->{success} eq 0) {
        print "Retrying Insert Scrape DB....";
        goto RE_INSERT_SCRAPE;
    }    
        
    #};
}
#END

### INI READER ###
sub readConfig($)
{
    my $ConfigFile = $_[0];
    my $Index = 0, my $Name = "";
    my $ConfigEntries;

    open (CONFIGFILE, $ConfigFile);
    while (my $line = <CONFIGFILE>)
    {
        chomp($line);
        next if ($line eq "");

        if ($line =~ /\[(.*)\]/)
        {
            $Name = $1;
            if (!defined($ConfigEntries->{$Name}))
            {
                $Index = 0;
            }
            #else
            #{
            #    $Index = scalar(@{$ConfigEntries->{$1}});
            #}
        }

        elsif ($line =~ /(.*)=(.*)/)
        {
            $ConfigEntries->{$Name}->{trim($1)} = trim($2);
        }
    }

    close CONFIGFILE;
    return $ConfigEntries;
}

#END

### TRIM FOR SPACES,TABS ###
sub trim($)
{
    my $str = $_[0];
    if($str eq "DAL"){
        $str = $_[1];
    }
    
    $str = (defined($str)) ? $str : "";
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    $str =~ s/^\t+//;
    $str =~ s/\t+$//;
    return($str);
}
#END

#BEGIN
sub checkExclusion($){
    my ($class,$location) = @_;
    

    $location = lc $location;
    #$location = "united states";
    my $result = 0;
    
    open (CONFIGFILE, "Exclusion.txt");
    while (my $line = <CONFIGFILE>)
    {
        chomp($line);
        $line = DAL->trim(lc $line);
        next if ($line eq "");
        #if (lc $location eq lc $line){

        $result = 1 if ($location =~ /$line/);
        return $result if($result eq 1);
    }

    close CONFIGFILE;
    return $result;
}
#END

#BEGIN
sub currentTime{
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    $year += 1900;
    $mon++;

    $mday = "0".$mday if(length($mday) == 1);
    $mon = "0".$mon if(length($mon) == 1);
    $hour = "0".$hour if(length($hour) == 1);
    $min = "0".$min if(length($min) == 1);
    $sec = "0".$sec if(length($sec) == 1);
    
    return "$year-$mon-$mday ". "$hour:$min:$sec";
}
#END

sub clear_HTML_tags(){
    my ($class, $description) = @_;
    my $p = HTML::Scrubber->new( allow => [ qw[ br li p tr ] ] );
    #All HTML 5 tags except BR
    $p->deny( qw[a abbr address area article aside audio b base bdo blockquote body button canvas caption cite code col colgroup command datalist dd del details dfn div dl dt em embed eventsource fieldset figcaption figure footer form h1 h2 h3 h4 h5 h6 head header hgroup hr html i iframe img input ins kbd keygen label legend link mark map menu meta meter nav noscript object ol optgroup option output param pre progress q ruby rp rt samp script section select small source span strong style sub summary sup table tbody td textarea tfoot th thead time title ul var video wbr] );    
    $description = $p->scrub($description);
    $description =~ s/\<br\s+\/+\>/\r\n/gi;  # REPLACE <BR> with new line
    $description =~ s/\<br\>/\r\n/gi;  # REPLACE <BR> with new line
    $description =~ s/\<p\>/\r\n/gi;  # REPLACE <BR> with new line
    $description =~ s/\<li\>/\t/gi;  # REPLACE <BR> with new line
    $description =~ s/\<\/li\>/\r\n/gi;  # REPLACE <BR> with new line
    $description =~ s/\<tr\>/\r\n/gi;  # REPLACE <BR> with new line
    $description =~ s/\<\/tr\>/\r\n/gi;  # REPLACE <BR> with new line
    return $description;
}

#BEGIN
sub get_country_code {
    my ($class, $country) = @_;
    my $country_code = $db->query("SELECT cou_code FROM country WHERE cou_desc = ?", $country)->list;
    return $country_code;
}
#END

1;