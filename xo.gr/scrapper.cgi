#!/usr/bin/perl

no warnings;
use strict;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Data::Dumper;
use Encode;
use HTML::TreeBuilder;
use POSIX;
use WWW::Mechanize;

my $q = new CGI;
print $q->header(-charset => 'utf-8');
#local $\ = "\n";

#my ($category, $start_page, $total_records, $location) = @ARGV;
my $category = $q->param('category');
my $start_page = $q->param('start_page');
my $total_records = $q->param('total_records');
my $location = $q->param('location');

my $page_records = 20;
$total_records ||= 600;
my $end_page = ceil ($total_records / $page_records);
$start_page ||= 1;

my $base_url = 'http://www.xo.gr/search/?what=%CE%B3%CE%B9%CE%B1%CF%84%CF%81%CF%8C%CF%82';
$base_url .= "&catFlt=$category" if $category;
$base_url .= "&locId=$location" if $location;

my (@categories, @locations, %unique);

my $mech = WWW::Mechanize->new();
$mech->agent('Mozilla/6.0');
#my $mech = WWW::Mechanize->new(agent => 'Mozilla/5.0');
#$mech->proxy(['https', 'http', 'ftp'], 'https://127.0.0.1:9051/');
#$mech->proxy(['http', 'ftp'], 'http://127.0.0.1:9051/');

#@categories = $mech->find_all_links(class => 'filter', url_regex => qr/catFlt=\d+$/);
#print scalar @categories . "\n";

#@locations  = $mech->find_all_links(url_regex => qr/locId=\w+$/);
#print scalar @locations . "\n";

#(@categories) = $mech->content() =~ m/catFlt=(\d+)/g;
#@unique{@categories} = ();
#@categories = sort {$a <=> $b} keys %unique;
#print scalar @categories . "\n@categories\n";

#(@locations) = $mech->content() =~ m/locId=(\w+)/g;
#@unique{@locations} = ();
#@locations = sort keys %unique;
#print scalar @locations . "\n@locations\n";

@categories = (3549, 3558, 3561, 3562, 3563, 3565, 3573, 3574, 3575, 3576, 3578, 3582, 3583, 3584, 3587, 3590, 3593, 3594, 3598, 3615, 3623, 3633, 3637, 3643, 3645, 3669, 3676, 3681, 3685, 3693, 3695, 3696, 3708, 3715, 3716, 3717, 3718, 3719, 3720, 3722, 3723, 3725, 3752, 3753, 3759, 3772, 3775, 3776, 3777, 3779, 3781, 3784, 3788, 3792, 3798, 3815, 3824, 3837, 3847, 3848, 3849, 3850, 3856, 3857, 3858, 3860, 3861, 3862, 3863, 3864, 3865, 3867, 3868, 3869, 3870, 3871, 3872, 3873, 3874, 3875, 3876, 3877, 3878, 3879, 3880, 3881, 3883, 3888, 3893, 3905, 3912, 3917, 3920, 3935, 3968, 3977, 3978, 3985, 4008, 4023, 4024, 4036, 4045, 4050, 4052, 4060, 4064, 4069, 4071, 4091, 4101, 4106, 4120, 4136, 4137, 4138, 4148, 4170, 4207, 4225, 4226, 4229, 4231, 4240, 4249, 4251, 4285, 4291, 4295, 4297, 4307, 4309, 4315, 4330, 4342, 4345, 4346, 4358, 4359, 4379, 4399, 4415, 4419, 4424, 4426, 4430, 4454, 4463, 5035, 5068, 5136, 5143, 5158, 5226, 5232, 5239, 5247, 5250, 5284, 5298, 5299, 5300, 5312, 5598, 5771, 5772);

@locations = ('B10', 'B11', 'B13', 'B14', 'B15', 'B16', 'B17', 'B19', 'B2', 'B20', 'B21', 'B22', 'B23', 'B24', 'B25', 'B26', 'B27', 'B28', 'B29', 'B3', 'B32', 'B33', 'B34', 'B35', 'B36', 'B38', 'B39', 'B4', 'B40', 'B41', 'B42', 'B43', 'B44', 'B45', 'B49', 'B5', 'B6', 'B7', 'B8', 'B9', 'L1', 'L10', 'L100', 'L1000', 'L1001', 'L101', 'L1015', 'L1019', 'L102', 'L1027', 'L103', 'L104', 'L105', 'L1050', 'L10533', 'L1055', 'L10560', 'L106', 'L1064', 'L1067', 'L1069', 'L107', 'L1070', 'L1076', 'L108', 'L109', 'L10919', 'L11', 'L110', 'L1108', 'L111', 'L1110', 'L1114', 'L112', 'L113', 'L1132', 'L1134', 'L1137', 'L114', 'L1148', 'L115', 'L1150', 'L116', 'L1162', 'L117', 'L1171', 'L118', 'L1185', 'L119', 'L1195', 'L1197', 'L12', 'L120', 'L1205', 'L121', 'L122', 'L1225', 'L1226', 'L123', 'L1231', 'L124', 'L1242', 'L125', 'L1252', 'L1253', 'L1259', 'L126', 'L1262', 'L1269', 'L127', 'L1275', 'L1279', 'L128', 'L1285', 'L1286', 'L1287', 'L129', 'L1290', 'L1297', 'L1299', 'L13', 'L130', 'L1304', 'L131', 'L1311', 'L1313', 'L132', 'L1321', 'L1325', 'L133', 'L1335', 'L1338', 'L134', 'L1343', 'L135', 'L1354', 'L1357', 'L1358', 'L136', 'L1360', 'L137', 'L138', 'L1383', 'L1384', 'L139', 'L14', 'L140', 'L1406', 'L141', 'L142', 'L1420', 'L1422', 'L143', 'L1435', 'L144', 'L1444', 'L1447', 'L145', 'L1455', 'L1456', 'L146', 'L147', 'L148', 'L1480', 'L1490', 'L1492', 'L1496', 'L15', 'L150', 'L1505', 'L1506', 'L1508', 'L151', 'L152', 'L153', 'L1536', 'L1537', 'L154', 'L1545', 'L1548', 'L155', 'L1556', 'L156', 'L157', 'L1570', 'L158', 'L1585', 'L1589', 'L159', 'L1599', 'L16', 'L160', 'L1602', 'L1608', 'L161', 'L162', 'L1621', 'L1623', 'L1627', 'L163', 'L1634', 'L164', 'L1644', 'L165', 'L1657', 'L166', 'L1665', 'L167', 'L1670', 'L1672', 'L168', 'L169', 'L17', 'L170', 'L1709', 'L171', 'L1716', 'L172', 'L173', 'L174', 'L1749', 'L175', 'L1758', 'L176', 'L1762', 'L177', 'L1779', 'L178', 'L1783', 'L179', 'L1790', 'L18', 'L180', 'L181', 'L1811', 'L1812', 'L1817', 'L1819', 'L182', 'L1824', 'L183', 'L1834', 'L184', 'L185', 'L1857', 'L186', 'L187', 'L188', 'L189', 'L19', 'L190', 'L191', 'L1913', 'L1916', 'L192', 'L193', 'L194', 'L1946', 'L195', 'L1953', 'L1954', 'L196', 'L1961', 'L1963', 'L1968', 'L197', 'L1971', 'L1974', 'L198', 'L1988', 'L199', 'L2', 'L20', 'L200', 'L201', 'L202', 'L203', 'L2032', 'L204', 'L205', 'L2050', 'L2051', 'L206', 'L2064', 'L207', 'L2074', 'L2076', 'L2077', 'L208', 'L209', 'L21', 'L210', 'L211', 'L2110', 'L212', 'L213', 'L214', 'L2159', 'L216', 'L2169', 'L217', 'L218', 'L2183', 'L219', 'L22', 'L220', 'L2205', 'L221', 'L2214', 'L2215', 'L222', 'L223', 'L2237', 'L224', 'L2247', 'L225', 'L2259', 'L226', 'L227', 'L228', 'L229', 'L23', 'L230', 'L2305', 'L231', 'L232', 'L233', 'L2337', 'L234', 'L235', 'L236', 'L2366', 'L237', 'L238', 'L239', 'L2393', 'L2396', 'L24', 'L240', 'L241', 'L2411', 'L2413', 'L242', 'L2427', 'L243', 'L244', 'L245', 'L246', 'L2468', 'L247', 'L2473', 'L2477', 'L2478', 'L248', 'L249', 'L2490', 'L2499', 'L25', 'L250', 'L251', 'L253', 'L254', 'L256', 'L257', 'L258', 'L2589', 'L259', 'L26', 'L260', 'L2602', 'L2606', 'L261', 'L2615', 'L2616', 'L262', 'L2620', 'L263', 'L264', 'L2647', 'L265', 'L266', 'L2666', 'L2667', 'L267', 'L2670', 'L268', 'L27', 'L270', 'L271', 'L272', 'L2729', 'L274', 'L275', 'L277', 'L278', 'L279', 'L28', 'L280', 'L2801', 'L281', 'L2815', 'L2817', 'L2822', 'L283', 'L285', 'L286', 'L287', 'L2874', 'L2880', 'L289', 'L2895', 'L29', 'L290', 'L291', 'L292', 'L293', 'L2936', 'L294', 'L2950', 'L297', 'L298', 'L3', 'L30', 'L300', 'L301', 'L3018', 'L3019', 'L302', 'L303', 'L304', 'L3048', 'L305', 'L3066', 'L307', 'L3076', 'L308', 'L3081', 'L31', 'L310', 'L311', 'L312', 'L3121', 'L315', 'L316', 'L317', 'L32', 'L320', 'L3202', 'L3205', 'L3207', 'L325', 'L326', 'L327', 'L3279', 'L328', 'L3284', 'L3288', 'L329', 'L33', 'L330', 'L3308', 'L331', 'L333', 'L3369', 'L337', 'L338', 'L3389', 'L339', 'L34', 'L340', 'L341', 'L342', 'L3421', 'L3425', 'L344', 'L345', 'L347', 'L348', 'L3483', 'L349', 'L35', 'L350', 'L3503', 'L351', 'L352', 'L353', 'L355', 'L356', 'L3560', 'L357', 'L359', 'L36', 'L360', 'L3604', 'L361', 'L363', 'L3650', 'L3651', 'L366', 'L367', 'L3672', 'L369', 'L37', 'L370', 'L371', 'L372', 'L373', 'L3745', 'L376', 'L378', 'L3786', 'L379', 'L38', 'L380', 'L381', 'L382', 'L3823', 'L3828', 'L383', 'L384', 'L3849', 'L386', 'L3863', 'L387', 'L389', 'L39', 'L390', 'L3904', 'L391', 'L392', 'L393', 'L394', 'L396', 'L397', 'L398', 'L4', 'L40', 'L4014', 'L402', 'L405', 'L407', 'L4081', 'L409', 'L41', 'L411', 'L412', 'L4126', 'L413', 'L4134', 'L414', 'L416', 'L418', 'L42', 'L420', 'L421', 'L425', 'L4252', 'L427', 'L428', 'L43', 'L430', 'L4308', 'L433', 'L434', 'L4357', 'L4367', 'L437', 'L439', 'L44', 'L440', 'L4428', 'L443', 'L445', 'L446', 'L4489', 'L449', 'L45', 'L451', 'L452', 'L453', 'L456', 'L457', 'L459', 'L46', 'L460', 'L461', 'L465', 'L466', 'L4673', 'L469', 'L47', 'L471', 'L477', 'L478', 'L48', 'L480', 'L482', 'L4828', 'L484', 'L485', 'L486', 'L487', 'L488', 'L4885', 'L49', 'L490', 'L4904', 'L4908', 'L492', 'L493', 'L4945', 'L495', 'L498', 'L4981', 'L499', 'L4999', 'L5', 'L50', 'L500', 'L501', 'L502', 'L504', 'L5047', 'L505', 'L5052', 'L507', 'L509', 'L5092', 'L51', 'L512', 'L516', 'L5162', 'L518', 'L519', 'L52', 'L520', 'L521', 'L525', 'L528', 'L529', 'L5297', 'L53', 'L530', 'L531', 'L533', 'L536', 'L54', 'L542', 'L5422', 'L543', 'L5457', 'L547', 'L55', 'L552', 'L5525', 'L555', 'L556', 'L557', 'L558', 'L56', 'L560', 'L5614', 'L568', 'L5682', 'L57', 'L570', 'L571', 'L5716', 'L58', 'L580', 'L5802', 'L585', 'L586', 'L59', 'L590', 'L5900', 'L593', 'L595', 'L596', 'L597', 'L598', 'L6', 'L60', 'L600', 'L601', 'L6043', 'L605', 'L607', 'L61', 'L613', 'L614', 'L619', 'L62', 'L623', 'L625', 'L626', 'L6288', 'L63', 'L630', 'L636', 'L637', 'L639', 'L64', 'L641', 'L644', 'L65', 'L650', 'L652', 'L655', 'L66', 'L661', 'L6613', 'L662', 'L6625', 'L669', 'L67', 'L672', 'L674', 'L676', 'L68', 'L681', 'L688', 'L6896', 'L69', 'L6901', 'L692', 'L693', 'L694', 'L695', 'L696', 'L697', 'L7', 'L70', 'L702', 'L706', 'L708', 'L71', 'L713', 'L716', 'L7179', 'L718', 'L72', 'L73', 'L7306', 'L731', 'L736', 'L738', 'L739', 'L74', 'L745', 'L746', 'L7479', 'L748', 'L75', 'L7572', 'L7579', 'L758', 'L76', 'L760', 'L762', 'L77', 'L78', 'L783', 'L785', 'L79', 'L791', 'L792', 'L8', 'L80', 'L801', 'L804', 'L81', 'L814', 'L816', 'L82', 'L820', 'L8217', 'L822', 'L825', 'L827', 'L83', 'L836', 'L839', 'L84', 'L840', 'L842', 'L843', 'L85', 'L855', 'L857', 'L86', 'L866', 'L87', 'L877', 'L878', 'L88', 'L882', 'L8835', 'L89', 'L8924', 'L9', 'L90', 'L900', 'L9035', 'L91', 'L916', 'L92', 'L920', 'L927', 'L93', 'L94', 'L943', 'L945', 'L949', 'L95', 'L951', 'L9515', 'L96', 'L963', 'L97', 'L9767', 'L98', 'L9839', 'L987', 'L99', 'L994', 'L999');

#print scalar @categories . "\n";
#print scalar @locations . "\n";

unless (-e './data/data.csv') {
    open (CSV, '>', './data/data.csv') || die $!;
    print CSV qq{"Name","Address","City/area","Telephone","Fax","Mobile","Category","Additional information","Email","Website"\n};
    close CSV;
}

open (CSV, '>>', './data/data.csv') || die $!;

#for my $page (1 .. 336) {
#for my $page ($start_page .. 336) {
for my $page ($start_page .. $end_page) {
    my $scrap_url = $base_url;
    $scrap_url .= "&page=$page" if $page > 1;
    print "url: $scrap_url<br>";
    print "page: $page<br>";

    eval {
        $mech->get($scrap_url);
    };

    if ($@) {
        print "Error connecting to URL $scrap_url. Exitting...<br>";
        last;
    }

    my $tree  = HTML::TreeBuilder->new_from_content(decode_utf8($mech->content()));
    my @items = $tree->look_down(_tag => 'div', class => 'top_sponsor');

    print 'items: ' . scalar @items . "<br>";
    print "last page: $end_page<br><br>";
    #next unless @items;
    last unless @items;

    my $count = 0;
    #for my $item (@items) {
    for (my $i = 0; $i < @items; $i++) {
        my $item = $items[$i];

        $count++;
        print "count: $count<br>";

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

        print "Name:$Name<br>";
        print "Address:$Address<br>";
        print "City:$City<br>";
        print "Telephone:$Telephone<br>";
        print "Fax:$Fax<br>";
        print "Mobile:$Mobile<br>";
        print "Category:$Category<br>";
        print "Addl_info:$Addl_info<br>";
        print "Email:$Email<br>";
        print "Website:$Website<br>";
        print "<br><br>";

        print CSV qq{"$Name","$Address","$City","$Telephone","$Fax","$Mobile","$Category","$Addl_info","$Email","$Website"\n};
    }
}

close CSV;
