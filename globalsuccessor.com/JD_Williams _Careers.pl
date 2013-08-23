#!/usr/bin/perl

no warnings;
use DAL;
use Encode;
use HTML::TreeBuilder;
use strict;
use WWW::Mechanize;

#DECLARATIONS
my $adv_info = DAL->read_advertiser_info;
my $search_url = "http://gs10.globalsuccessor.com/fe/tpl_whitbread.asp?nexts=INIT_JOBLISTSTART";
my $dup_count = 0;
my $mech = WWW::Mechanize->new();

#-------------------------#
# MAIN PROGRAM            #
#-------------------------#

print "########## Scrapping from Whitbread ###########\n";
local $SIG{__WARN__} = sub {
    warn @_ unless $_[0] =~ m/^.* too (?:big|small)/;
};

do {
	eval {
		$mech->get($search_url);
	};

	if ($@) {
		print "Error connecting to URL $search_url. Going to next page. Restart script required at the end...\n";
		next;
	} else {
		my $next_page = $mech->find_link(class => 'ForwardBulletGif', text => 'Next Page');
		$search_url = $next_page ? $next_page->url_abs() : '';

		my $root = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));

		my @allLinks = $mech->find_all_links(url_regex => qr/jobid=\d+,/);

		for my $link (@allLinks) {
			my $url = $link->url_abs();

			eval {
				$mech->get($url);
			};
			next if $@;

			my $details = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));
			my $title = $details->look_down(_tag => 'h2')->as_trimmed_text;
			my @dds = $details->look_down(_tag => 'dd', class => 'codeListValue');
			my $ref = $dds[0]->as_trimmed_text;
			my $loc = $dds[1]->as_trimmed_text;
			my $description = $details->look_down(_tag => 'div', id => 'description')->as_trimmed_text;

			process_job($title, $url, $ref, $loc, $description);
		}
	}
} while ($search_url);

print "######## COMPLETED #########\n";
exit 0;


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
	$title =~ s/Whitbread//smgi;
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