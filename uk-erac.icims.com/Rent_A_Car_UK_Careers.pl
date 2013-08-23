#!/usr/bin/perl

no warnings;
use DAL;
use Encode;
use HTML::TreeBuilder;
use POSIX;
use strict;
use WWW::Mechanize;

#DECLARATIONS
my $adv_info = DAL->read_advertiser_info;
my $search_url = "https://uk-erac.icims.com/jobs/search";
my $dup_count = 0;
my $mech = WWW::Mechanize->new();

#BEGIN METHOD
sub process_job($$$$$) {
    my $title = $_[0];
    my $url = $_[1];
    my $ref = $_[2];
    my $loc = $_[3];
    my $description = $_[4];

    print "Parsing Job: -> $ref\n";
    #Check Scrape vacancies
    if (DAL->check_scrape_vacancies($ref)) {
        $dup_count++;
        if (DAL->max_duplicate_reached($dup_count) == 1) {
			print "Maximum number of duplicates reached...EXITTING...\n";
			exit(0);
        }
        print "$ref already exists....SKIPPING\n";
		return;
    }

    #SKIP processing if Location found in Exclusion List
    if (DAL->checkExclusion($loc) == 1) {
        print "Skipping, found in exclusion list ... $loc\n";
        #next GET_NEXT_JOB;
        return;
    }

    my $pos = 'P';
    my $sal = '';
    my $timestamp = DAL->currentTime;
    my $html = '';

    #adv_tel,adv_cont_1,adv_title,adv_add1,adv_add2,adv_add3,adv_add4,adv_pcode,adv_email
    $title = substr $title, 0, 54;
    $title = DAL->trim($title);
    $loc = substr $loc, 0, 29;

    my $data = {
		vac_cre_dte => $timestamp,
		vac_status => 1,
		vac_job_title => $title || '',
		vac_phone => $adv_info->[0] || '',
		vac_contact => $adv_info->[1] || '',
		vac_title =>$adv_info->[2] || '',
		vac_needed => 0,
		vac_duration => 0,
		vac_dur_type => 1,
		vac_add1 =>$adv_info->[3] || '',
		vac_add2 =>$adv_info->[4] || '',
		vac_add3 =>$adv_info->[5] || '',
		vac_add4 =>$adv_info->[6] || '',
		vac_pcode =>$adv_info->[7] || '',
		vac_machine => 'Web',
		vac_modified => $timestamp,
		vac_user => 'Robot',
		vac_text => $html,
		vac_locn => $loc || '', #Location
		vac_type => $pos || '', #Permanent / Temporary
		vac_salary => $sal || '', #Salary
		vac_advjob => $ref, # Job Reference number
		vac_effective => $timestamp,
		vac_email => $adv_info->[8] || '',
		vac_url => $url || '',
		vac_jd => $description || '',
		vac_lsource => 'Customer Site',
		vac_f_source => 1,
		vac_fax => $adv_info->[9] || '',
		sv_ref => $ref
    };

    #Record To Database
    print "Saving Job ID: $ref to vacancy and scrap_vacancy table...\n";

    #Record to Database Extracted vacany Information
    DAL->insert_vacancy($data);
    print "Job successfully saved!...\n\n";
}
#END METHOD

#-------------------------#
# MAIN PROGRAM            #
#-------------------------#


print "########## Scrapping from Rent A Car ###########\n";
local $SIG{__WARN__} = sub {
    warn @_ unless $_[0] =~ m/^.* too (?:big|small)/;
};

my ($total_pages, $page_no) = (0, 1);
do {
	eval {
		$mech->get("$search_url?pr=$page_no");
	};
	if ($@) {
		print "Error connecting to URL $search_url?pr=$page_no. Going to next page. Restart script required at the end...\n";
		next;
	}

	my $root = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));
	unless ($total_pages) {
		$total_pages = $root->look_down(_tag => 'td', class => 'iCIMS_JobsTablePaging')->as_trimmed_text;
		($total_pages) = $total_pages =~ /of\s(\d+)/;
	}

	my @allLinks = $mech->find_all_links(class => 'iCIMS_Anchor iCIMS_JobsTableOddAnchor');
	push @allLinks, $mech->find_all_links(class => 'iCIMS_Anchor iCIMS_JobsTableEvenAnchor');
	for my $link (@allLinks) {
		my $url = $link->url_abs();

		eval {
			$mech->get($url);
		};
		next if $@;

		my $details = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));
		my $title = $details->look_down(_tag => 'td', class => 'iCIMS_Header iCIMS_Header_JobTitle')->as_trimmed_text;
		my @tds = $details->look_down(class => 'iCIMS_JobHeaderTable')->look_down(_tag => 'td');
		my $ref = $tds[0]->as_trimmed_text;
		my $loc = $tds[1]->as_trimmed_text;
		my $description = ($details->look_down(_tag => 'td', class => 'iCIMS_InfoMsg iCIMS_InfoMsg_Job'))[3]->as_trimmed_text;
		process_job($title, $url, $ref, $loc, $description);
	}

	$page_no++;
} while ($page_no <= $total_pages);

print "######## COMPLETED #########\n";
exit 0;
