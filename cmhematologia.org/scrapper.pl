#!/usr/bin/perl

no warnings;
use strict;
use Data::Dumper;
use Encode;
use HTML::TreeBuilder;
use Text::CSV;
use WWW::Mechanize;

#local $\ = "\n";

#DECLARATIONS
my $url = "http://www.cmhematologia.org/DoctoresBD.aspx";
my @options = ('AGS.', 'B.C.', 'B.C.S.', 'BOLIVIA', 'CAM.', 'CAMPECHE', 'CHIH.', 'CHIS.', 'COAH.', 'COL.', 'D.F.', 'DGO.', 'DISTRITO FEDERAL', 'EUA', 'GRO.', 'GTO.', 'HGO.', 'HIDALGO', 'JAL.', 'MEX.', 'MICH.', 'MOR.', 'MORELOS', 'N.L.', 'NAY.', 'OAX.', 'PUE.', 'PUEBLA', 'Q. ROO', 'QRO.', 'S.L.P.', 'SAN LUIS POTOSI', 'Sin Datos', 'SIN.', 'SON.', 'TAB.', 'TAMPS.', 'TX.', 'VER.', 'YUC.', 'ZAC.');

my $mech = WWW::Mechanize->new();

open (CSV, '>', 'data.csv') || die $!;
print CSV qq{"Title","Forename","Father Name","Mother Name","Institution","Department","Street","Suburb","Postcode","City","State","Email","Phone1","Extension1","Phone2","Extension2"\n};

for (@options) {
	eval {
		$mech->get($url);
	};

	if ($@) {
		print "Error connecting to URL $_. Skipping...\n";
		next;
	}

	$mech->select('ctl00$Contenido$DropDownList1', $_);
	$mech->submit();

	my @links = $mech->find_all_links(text => 'Cambiar Datos', url_regex => qr/DoctoresDetalle.aspx\?dr=\d+$/);
	#print scalar @links;
	for my $link (@links) {
		my $details_url = $link->url_abs();
		my $details_mech = WWW::Mechanize->new();
		eval {
			$details_mech->get($details_url);
		};

		if ($@) {
			print "Error connecting to URL $details_url. Skipping...\n";
			next;
		}
		my @details	= $details_mech->find_all_inputs(type => 'text');
		print CSV qq{"$_->{value}",} for @details;
		print CSV qq{\n};
		#print "@details";
		
=head
		my $tree 		= HTML::TreeBuilder->new_from_content(decode_utf8($details_mech->content()));
		my $td 			= $tree->look_down(_tag => 'td', colspan => 2);
		my $Title 		= $td->look_down(_tag => 'input', name => 'ctl00$Contenido$FormView1$TituloTextBox')->{value};
		my $Forename 	= $td->look_down(_tag => 'input', name => 'ctl00$Contenido$FormView1$NombreTextBox')->{value};
		my $Father_Name = $td->look_down(_tag => 'input', name => 'ctl00$Contenido$FormView1$ApellidoPaternoTextBox')->{value};
		my $Mother_Name = $td->look_down(_tag => 'input', name => 'ctl00$Contenido$FormView1$ApellidomaternoTextBox')->{value};
		my $Institution = $td->look_down(_tag => 'input', name => 'ctl00$Contenido$FormView1$HospitalTextBox')->{value};
		my $Department 	= $td->look_down(_tag => 'input', name => 'ctl00$Contenido$FormView1$DepartamentoServicioTextBox')->{value};
		my $Street 		= $td->look_down(_tag => 'input', name => 'ctl00$Contenido$FormView1$DireccionTextBox')->{value};
		my $Suburb 		= $td->look_down(_tag => 'input', name => 'ctl00$Contenido$FormView1$ColoniaTextBox')->{value};
		my $Postcode 	= $td->look_down(_tag => 'input', name => 'ctl00$Contenido$FormView1$CPTextBox')->{value};
		my $City 		= $td->look_down(_tag => 'input', name => 'ctl00$Contenido$FormView1$Ciudad_PoblacionTextBox')->{value};
		my $State 		= $td->look_down(_tag => 'input', name => 'ctl00$Contenido$FormView1$EstadoTextBox')->{value};
		my $Email 		= $td->look_down(_tag => 'input', name => 'ctl00$Contenido$FormView1$CorreoTextBox')->{value};
		my $Phone1 		= $td->look_down(_tag => 'input', name => 'ctl00$Contenido$FormView1$TelefonoTextBox')->{value};
		my $Extension1 	= $td->look_down(_tag => 'input', name => 'ctl00$Contenido$FormView1$ExtensionTextBox')->{value};
		my $Phone2 		= $td->look_down(_tag => 'input', name => 'ctl00$Contenido$FormView1$Telefono2TextBox')->{value};
		my $Extension2 	= $td->look_down(_tag => 'input', name => 'ctl00$Contenido$FormView1$Extension2TextBox')->{value};
=cut
	}
}

close CSV;


#my ($options) = $mech->find_all_inputs(
#	type => 'option',
#    name => 'ctl00$Contenido$DropDownList1',
#);
#my @options = map {$_->{value}} @{$options->{menu}};

sub writeHTML {
	my ($page, $mech) = @_;
    open my $fh, '>' ,"$page.htm" or die "@! $! failed to write";
    print $fh $mech->content();
    close $fh;
}