#!/usr/bin/perl

no warnings;
use strict;
use DAL;
use Encode;
use HTML::TreeBuilder;
use POSIX;
use WWW::Mechanize;

#DECLARATIONS
my $adv_info = DAL->read_advertiser_info;
my $search_url = "http://gs10.globalsuccessor.com/fe/tpl_whitbread.asp?nexts=INIT_JOBLISTSTART";
my $job_url = "https://www.goodrich.apply2jobs.com/ProfExt/index.cfm?fuseaction=mExternal.showJob&RID=";
my $dup_count = 0;
my $mech = WWW::Mechanize->new();

#BEGIN METHOD
sub process_job($$$$$$) {
    my $title = $_[0];
    my $url = $_[1];
    my $ref = $_[2];
    my $loc = $_[3];
	my $country = $_[4];
    my $description = $_[5];

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
    if (DAL->checkExclusion("$loc $country") == 1) {
        print "Skipping, found in exclusion list ... $loc\n";
        #next GET_NEXT_JOB;
        return;
    }

    my $pos = 'P';
    my $sal = '';
    my $timestamp = DAL->currentTime;
    my $html = '';

    #adv_tel,adv_cont_1,adv_title,adv_add1,adv_add2,adv_add3,adv_add4,adv_pcode,adv_email
	$title =~ s/Goodrich//smgi;
    $title = substr $title, 0, 54;
    $title = DAL->trim($title);
    $loc = substr $loc, 0, 29;
	my $country_code = DAL->get_country_code($country);

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
		sv_ref => $ref,
		vac_country => $country_code || $country
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


print "########## Scrapping from Goodrich ###########\n";
local $SIG{__WARN__} = sub {
    warn @_ unless $_[0] =~ m/^.* too (?:big|small)/;
};

my ($total_jobs, $total_pages, $jobs_per_page, $page_no) = (0, 0, 10, 1);
do {
	eval {
		$mech->get($search_url);
	};

	if ($@) {
		print "Error connecting to URL $search_url?CurrentPage=$page_no. Going to next page. Restart script required at the end...\n";
	}
	else {
		my $next_page = $mech->find_link(class => 'ForwardBulletGif', url_regex => qr/Next Page/);
		my $root = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));

		unless ($total_pages) {
			$total_jobs = (($root->look_down(_tag => 'td', class => 'VEContentText'))[0]->look_down(_tag => 'b'))[1]->as_trimmed_text;
			$total_pages = ceil($total_jobs / $jobs_per_page);
			print "total_jobs: $total_jobs, total_pages: $total_pages\n";
		}
		print "page_no: $page_no\n";

		my $table = $root->look_down(_tag => 'table', class => 'SearchResultsTable');
		my @trs = $table->look_down(_tag => 'tr');
		for (1 .. $#trs) {
			my @tds = $trs[$_]->look_down(_tag => 'td');
			my $title   = DAL->trim($tds[0]->as_trimmed_text);
			my $country = DAL->trim($tds[2]->as_trimmed_text);
			my $state   = DAL->trim($tds[3]->as_trimmed_text);
			my $city    = DAL->trim($tds[4]->as_trimmed_text);
			my $ref     = DAL->trim($tds[5]->as_trimmed_text);
			my $url		= "$job_url$ref";

			eval {
				$mech->get($url);
			};
			next if $@;

			my $details = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));
			my $description = (($details->look_down(_tag => 'table', class => 'JobDetailTable')->look_down(_tag => 'tr'))[2]->look_down(_tag => 'td'))[1]->as_trimmed_text;
			process_job($title, $url, $ref, $city, $country, $description);
		}
	}

	$page_no++;
} while ($page_no <= $total_pages);

print "######## COMPLETED #########\n";
exit 0;
