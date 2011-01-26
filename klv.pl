#!/usr/bin/perl
##########################################################################################################
#
# Kismet Log Viewer 0.9.7 - By Brian Foy Jr. - 4/13/2003
#
# Outputs html interface to Kismet .xml log files.
#
# Requires: 
# The XML::LibXML perl module
# At leaast one Kismet .xml logfile.
#
# 	Optional: 
# 	Snort (http://www.snort.org/)
# 	The .dump logfile that matches the .xml logfile.
#
# To Use:
# Either make sure that the 3 included files: 
# logo.png, ap_manuf, and client_manuf are in the same dir as the log you are going to use or, 
# if you prefer, drop them into a set dir (like /etc/klv) and update the lines below to reflect 
# their new location.
#
# Note: ap_manuf and client_manf are the files that come with Kismet. It may be a good idea
# to just point those two lines to the Kismet files so that when Kismet updates them, 
# klv will use the new files by default.
#
# Example:
# $logo_location = "/etc/klv/logo.png";
# $ap_manuf_location = "/etc/kismet/ap_manuf";
# $client_manuf_location = "/etc/kismet/client_manuf";

$logo_location         = "logo.png";
$ap_manuf_location     = "ap_manuf";
$client_manuf_location = "client_manuf";

# 	Optionaly: 
# 	At this point you can combine some log files using the included klc.pl script. See klc.pl for more options.
#
# 	Example:
# 	./klc.pl *.xml
#
# Then:
# ./klv.pl (logfile).xml
#
# 	Optionaly:
# 	If you have Snort and the .dump file from the same run, you can use -snort to 
# 	generate a page for the Snort output for each specific bssid that has data avilable.
#
# 	Example:
# 	./klv.pl (logfile).xml -snort
#
# And Finaly:
# Open the (logfile).xml-kismet-log-view.html in your fav browser.
#
# 	Other Options:
#
#       Set the alignment of the bssid's, center by default. Standard HTML 
#	aligments apply, left, right, etc.

$ssid_align = "center"; 

#       Set the character to be used in the clients column when there are 0 clients. 
#       This default's to - but can be 0 or any other character you choose.

$no_clients_char = "-";

#
# Enjoy! 
# The help and about links point to:
# http://www.mindflip.org/klv/help.html and http://www.mindflip.org/klv/about.html respectivly 
# you can see those for more info.
#
# Please send bugs, feature requests, questions, suggestions to: klv@mindflip.org
# Watch http://www.mindflip.org/klv for updates. 
#
##########################################################################################################

use XML::LibXML;

############################################################
#NOTE: There must be at least 1 argument sent to the program
############################################################
unless ( @ARGV > 0 ) 
{
    print "Usage: $0 <logfile> [-snort]\n";
    exit;
}

############################################################################
#The first argument is always the file that we want to process (i.e the log)
#Sets some variables leading to external URLs
#############################################################################
$file = $ARGV[0];

$help_location  = "http://www.mindflip.org/klv/help.html";
$about_location = "http://www.mindflip.org/klv/about.html";
$net_stats_link = "$file" . "-kismet-log-view-" . "stats.html";

#####################################################################################################
#if '-snort' is an argument then we call &do_snort, which I can only assume does something with Snort
#####################################################################################################
if ( "$ARGV[1]" eq "-snort" ) 
{
    print "\nKLV: Running Snort...\n";

    &do_snort;
    $snort_ok = 1;
}

#############################################################
#Print loading status to the console, do administrative stuff
#Open the files that are key to identifying AP and Client data
#Open the Whitelist file (soon to be implemented as a database instead?)
#############################################################
print "KLV: Loading AP Manuf Data...\n";

open( AP_FILE, "$ap_manuf_location" );
@ap_manf = <AP_FILE>;
close(AP_FILE);

print "KLV: Loading Client Manuf Data...\n";

open( CLIENT_FILE, "$client_manuf_location" );
@client_manf = <CLIENT_FILE>;
close(CLIENT_FILE);

open( SEEN_BEFORE, "seen.txt");

open (WHITELIST, "whitelist.txt");
@whitelist = <WHITELIST>;
close (WHITELIST);

print "KLV: Loading Logfile...\n";

$parser = XML::LibXML->new();
$parser->expand_entities(0);
$tree = $parser->parse_file($file);
$root = $tree->getDocumentElement;

$kismet_ver        = $root->getAttribute('kismet-version');
$kismet_start_time = $root->getAttribute('start-time');
$kismet_end_time   = $root->getAttribute('end-time');


#########################################
#Print out HTML header template
#########################################
print "KLV: Generating main HTML File...\n";
#prints out the .html
$html_out_file = "$file" . "-kismet-log-view.html";
open( HTML_OUT, ">$html_out_file" );
#sets up the header
print HTML_OUT <<EOM;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>Kismet Log Viewer 1.1 - By Brian Foy Jr, Enhanced By Jeff Shi. </title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>
<body leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="1024" border="0" align="center" cellpadding="5" cellspacing="1">
  <tr> 
    <td width="30%"><a href="$html_out_file"><img src="$logo_location" width="214" height="77" border="0"></a></td>
    <td width="70%" align="right" valign="top"><br><br><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><a href="$help_location">help</a> - <a href="$about_location">about</a> - <a href="$net_stats_link">stats</a><br></font></td>
  </tr>
</table>
<table width="1024" border="0" align="center" cellpadding="5" cellspacing="1" bgcolor="#efefef">
  <tr bgcolor="#cecece"> 
    <td width="20"> 
      <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Net</font></div></td>
    <td width="120"> 
      <div align="$ssid_align"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Name 
        (SSID)</font></div></td>
    <td width="25"> 
      <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Type</font></div></td>
    <td width="20"> 
      <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Wep</font></div></td>
    <td width="20"> 
      <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Ch</font></div></td>
    <td width="50"> 
      <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Packets</font></div></td>
    <td width="135"> 
      <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Type/BSSID</font></div></td>
    <td width="30"> 
      <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Clients</font></div></td>
    <td width="170"> 
      <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">First 
        Seen </font></div></td>
    <td width="170"> 
      <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Last 
        Seen</font></div></td>
	<td width="170"> 
      <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Whitelisted?</font></div></td>
  </tr>
EOM


#########################################
#Extract all the network data
#########################################
$total_networks = @networks = $root->getElementsByTagName('wireless-network');
$total_factory_defaults = 0;
$total_wep = 0;
$total_cloaked = 0;
#Extract all the attributes
foreach $this_network (@networks) 
{

    $total_clients_this_net = @net_clients =
      $this_network->getElementsByTagName('wireless-client');

    $total_clients += $total_clients_this_net;

    $net_number  = $this_network->getAttribute('number');
    $net_type    = $this_network->getAttribute('type');
    $net_wep     = $this_network->getAttribute('wep');
    $net_cloaked = $this_network->getAttribute('cloaked');

	undef $net_device_cloaked;

	if ("$net_cloaked" eq "true") 
	{
		$net_device_cloaked = 1;  
		$total_cloaked++;
	} 

    $net_carrier = $this_network->getAttribute('carrier');
    $net_first   = $this_network->getAttribute('first-time');
    $net_last    = $this_network->getAttribute('last-time');
    if ( $temp = $this_network->getElementsByTagName('SSID')->[0] ) 
	{
        $net_ssid =
          $this_network->getElementsByTagName('SSID')
          ->[0]->getFirstChild->getData;
    }
    elsif ( $temp = $this_network->getElementsByTagName('info')->[0] ) 
	{
        $net_ssid =
          $this_network->getElementsByTagName('info')
          ->[0]->getFirstChild->getData;
    }
    else 
	{
        $net_ssid = "NA";
    }
    $net_bssid =
      $this_network->getElementsByTagName('BSSID')->[0]->getFirstChild->getData;
    $net_channel =
      $this_network->getElementsByTagName('channel')
      ->[0]->getFirstChild->getData;
    $net_maxrate =
      $this_network->getElementsByTagName('maxrate')
      ->[0]->getFirstChild->getData;
    $net_packets_LLC =
      $this_network->getElementsByTagName('LLC')->[0]->getFirstChild->getData;
    $net_packets_data =
      $this_network->getElementsByTagName('data')->[0]->getFirstChild->getData;
    $net_packets_crypt =
      $this_network->getElementsByTagName('crypt')->[0]->getFirstChild->getData;
    $net_packets_weak =
      $this_network->getElementsByTagName('weak')->[0]->getFirstChild->getData;
    $net_packets_total =
      $this_network->getElementsByTagName('total')->[0]->getFirstChild->getData;

    $total_packets += $net_packets_total;

    if ( $temp = $this_network->getElementsByTagName('datasize')->[0] ) 
	{
        $net_datasize =
          $this_network->getElementsByTagName('datasize')
          ->[0]->getFirstChild->getData;
    }
    else 
	{
        $net_datasize = "NA";
    }

    if ( $temp = $this_network->getElementsByTagName('min-lat')->[0] ) 
	{
        $net_gps_min_lat =
          $this_network->getElementsByTagName('min-lat')
          ->[0]->getFirstChild->getData;
        $net_gps_min_lon =
          $this_network->getElementsByTagName('min-lon')
          ->[0]->getFirstChild->getData;
        $net_gps_min_alt =
          $this_network->getElementsByTagName('min-alt')
          ->[0]->getFirstChild->getData;
        $net_gps_min_spd =
          $this_network->getElementsByTagName('min-spd')
          ->[0]->getFirstChild->getData;
        $net_gps_max_lat =
          $this_network->getElementsByTagName('max-lat')
          ->[0]->getFirstChild->getData;
        $net_gps_max_lon =
          $this_network->getElementsByTagName('max-lon')
          ->[0]->getFirstChild->getData;
        $net_gps_max_alt =
          $this_network->getElementsByTagName('max-alt')
          ->[0]->getFirstChild->getData;
        $net_gps_max_spd =
          $this_network->getElementsByTagName('max-spd')
          ->[0]->getFirstChild->getData;
        $net_gps_med_lon = ( ( $net_gps_min_lon + $net_gps_max_lon ) / 2 );
        $net_gps_med_lat = ( ( $net_gps_min_lat + $net_gps_max_lat ) / 2 );
        $net_gps_aprox_map1 =
"http://tiger.census.gov/cgi-bin/mapper/map.gif?&lat=$net_gps_med_lat&lon=$net_gps_med_lon&ht=0.004&wid=0.011&&tlevel=-&tvar=-&tmeth=i&mlat=$net_gps_med_lat&mlon=$net_gps_med_lon&msym=cross&mlabel=N$net_number&murl=&conf=mapnew.con&iht=359&iwd=422";
        $net_gps_aprox_map2 =
"http://tiger.census.gov/cgi-bin/mapper/map.gif?&lat=$net_gps_med_lat&lon=$net_gps_med_lon&ht=0.009&wid=0.022&&tlevel=-&tvar=-&tmeth=i&mlat=$net_gps_med_lat&mlon=$net_gps_med_lon&msym=cross&mlabel=N$net_number&murl=&conf=mapnew.con&iht=359&iwd=422";
        $net_gps_aprox_map3 =
"http://tiger.census.gov/cgi-bin/mapper/map.gif?&lat=$net_gps_med_lat&lon=$net_gps_med_lon&ht=0.018&wid=0.044&&tlevel=-&tvar=-&tmeth=i&mlat=$net_gps_med_lat&mlon=$net_gps_med_lon&msym=cross&mlabel=N$net_number&murl=&conf=mapnew.con&iht=359&iwd=422";
        $net_gps_aprox_map4 =
"http://tiger.census.gov/cgi-bin/mapper/map.gif?&lat=$net_gps_med_lat&lon=$net_gps_med_lon&ht=0.036&wid=0.088&&tlevel=-&tvar=-&tmeth=i&mlat=$net_gps_med_lat&mlon=$net_gps_med_lon&msym=cross&mlabel=N$net_number&murl=&conf=mapnew.con&iht=359&iwd=422";
        $net_gps_aprox_map5 =
"http://tiger.census.gov/cgi-bin/mapper/map.gif?&lat=$net_gps_med_lat&lon=$net_gps_med_lon&ht=0.064&wid=0.192&&tlevel=-&tvar=-&tmeth=i&mlat=$net_gps_med_lat&mlon=$net_gps_med_lon&msym=cross&mlabel=N$net_number&murl=&conf=mapnew.con&iht=359&iwd=422";
        $net_gps_aprox_map_avilable =
"(+) <a href=\"$net_gps_aprox_map1\" target=\"_blank\">1</a> <a href=\"$net_gps_aprox_map2\" target=\"_blank\">2</a> <a href=\"$net_gps_aprox_map3\" target=\"_blank\">3</a> <a href=\"$net_gps_aprox_map4\" target=\"_blank\">4</a> <a href=\"$net_gps_aprox_map5\" target=\"_blank\">5</a> (-)";
    }
    else 
	{
        $net_gps_min_lat            = "NA";
        $net_gps_min_lon            = "NA";
        $net_gps_min_alt            = "NA";
        $net_gps_min_spd            = "NA";
        $net_gps_max_lat            = "NA";
        $net_gps_max_lon            = "NA";
        $net_gps_max_alt            = "NA";
        $net_gps_max_spd            = "NA";
        $net_gps_aprox_map          = "NA";
        $net_gps_aprox_map_avilable = "NA";
    }

    if ( $temp = $this_network->getElementsByTagName('ip-range')->[0] ) 
	{
        $net_ip_range =
          $this_network->getElementsByTagName('ip-range')
          ->[0]->getFirstChild->getData;
        @net_ip_parts = $this_network->getElementsByTagName('ip-address');
        foreach $this_ip (@net_ip_parts) 
		{
            $net_ip_type = $this_ip->getAttribute('type');
        }
    }
    else 
	{
        $net_ip_range = "NA";
        $net_ip_type  = "NA";
    }


    $net_link = "$file" . "-kismet-log-view-" . "$net_number" . "-info.html";

    $net_clients_total = @net_clients;

    if ("$net_clients_total" eq "0") 
	{
		$net_clients_total = "$no_clients_char";
    }

    $net_clients_link =
      "$file" . "-kismet-log-view-" . "$net_number" . "-clients.html";

    $net_type = substr( $net_type, 0, 2 );
    if ( "$net_type" eq "in" ) { $net_type = "AP"; }

    if ( "$net_wep" eq "true" ) { $net_wep = "Y"; $total_wep++; }
    else { $net_wep = "N"; }

    if ( "$net_cloaked" eq "true" ) { $net_cloaked = "Y"; }
    else { $net_cloaked = "N"; }

    $net_first =~ s/  / /g;
    $net_last  =~ s/  / /g;

    @first_parts = split ( / /, $net_first );

    @last_parts = split ( / /, $net_last );

    $net_device_name = "NA";
    undef $net_device_def;
    foreach $ap_manuf_line (@ap_manf) {
        chomp $ap_manuf_line;
        @ap_manuf_line_parts = split ( /\t/, $ap_manuf_line );
        if ( $net_bssid =~ /$ap_manuf_line_parts[0]/ ) {
            $net_device_name =
              "$ap_manuf_line_parts[1] $ap_manuf_line_parts[2]";

		if ("$net_channel" eq "$ap_manuf_line_parts[4]") {
		
			if ("$net_ssid" eq "$ap_manuf_line_parts[3]") {
			$net_device_def = 1;
		    }

			if ("$net_ip_range" eq "NA") {
			$net_ip_range .= " ($ap_manuf_line_parts[5])";
			} else {
			$net_ip_range = "$net_ip_range ($ap_manuf_line_parts[5])";
			}		
		}

        }
    }

    if ( $net_number % 2 == 0 ) {
        print HTML_OUT "<tr>";
    }
    else {
        print HTML_OUT "<tr bgcolor=\"#FFFFFF\">";
    }

    if ($snort_ok) {
        undef $this_net_snort;
        $mod_bssid = $net_bssid;
        $mod_bssid =~ s/://g;
        if ( $network_packets{"$mod_bssid"} ) {
            print "KLV: Extracting Snort Data for $net_ssid ...\n";
            &gen_snort($mod_bssid);
            $this_net_snort = 1;
        }
    }


undef $flags;
    if ($net_device_cloaked) {
	$flags .= "C";
	$total_factory_defaults++;
	}
    if ($net_device_def) {
	$flags .= "F";
	$total_factory_defaults++;
	}
    if ($this_net_snort) {
	$flags .= "<a href=\"$net_snort_link\">D</a>";
	}

$net_total_unwep = eval($total_networks - $total_wep);
$net_percent_wep = eval($total_wep / $total_networks) * 100;
$net_percent_wep = substr($net_percent_wep,0,4);

$net_percent_factory_default = eval($total_factory_defaults / $total_networks) * 100;
$net_percent_factory_default = substr($net_percent_factory_default,0,4);

$net_percent_cloaked = eval($total_cloaked / $total_networks) * 100;
$net_percent_cloaked = substr($net_percent_cloaked,0,4);

$is_whitelisted = 'no';
$whitelist_td_color = 'EE6363';
foreach $whitelist (@whitelist)
{
	if ($net_ssid eq $whitelist)
	{
		$is_whitelisted = 'yes';
		$whitelist_td_color = '66CD00';
	}
}


print $net_bssid;

        print HTML_OUT <<EOM;
<td width="20"><div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_number$flags</font></div></td>
<td width="120"><div align="$ssid_align"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="$net_link">$net_ssid</a></font></div></td>
<td width="25"><div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_type</font></div></td>
<td width="20"><div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_wep</font></div></td>
<td width="20"><div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_channel</font></div></td>
<td width="50"><div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_packets_total</font></div></td>
<td width="75"><div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_device_name<br>$net_bssid</font></div></td>
EOM

	if ($net_clients_total > 0) {
    print HTML_OUT <<EOM;
<td width="50"><div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="$net_clients_link">$net_clients_total</a></font></div></td>
EOM
	} 
	else { #print out the link to net_clients and # of clients
    print HTML_OUT <<EOM;
<td width="50"><div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_clients_total</font></div></td>
EOM
	}

    print HTML_OUT <<EOM;
<td width="200"><div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$first_parts[0] $first_parts[1] $first_parts[2]<br>$first_parts[3]</font></div></td>
<td width="200"><div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$last_parts[0] $last_parts[1] $last_parts[2]<br>$last_parts[3]</font></div></td>
<td width="200" BGCOLOR=$whitelist_td_color><div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$is_whitelisted</font></div></td>
</tr>
EOM


######################################################
#Here we generate a separate page for each detected AP
#######################################################

    print "KLV: Generating details for network #$net_number ($net_ssid) ...\n";

    open( HTML_NET_OUT, ">$net_link" );

    print HTML_NET_OUT <<EOM;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>Kismet Log Viewer 1.0 - By Brian Goy Jr. </title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>
<body leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="760" border="0" align="center" cellpadding="5" cellspacing="1">
  <tr> 
    <td width="30%"><a href="$html_out_file"><img src="$logo_location" width="214" height="77" border="0"></a></td>
    <td width="70%" align="right" valign="top"><br><br><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><a href="$help_location">help</a> - <a href="$about_location">about</a> - <a href="$net_stats_link">stats</a><br></font></td>
  </tr>
</table>
<table width="760" border="0" align="center" cellpadding="5" cellspacing="1" bgcolor="#efefef">
  <tr bgcolor="#cecece"> 
    <td width="200"> 
      <div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_ssid</font></div></td>
    <td width="540"> 
      <div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Type: $net_device_name ($net_bssid)</font></div></td>
  </tr>
<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Net</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_number</font></div></td>
</tr>
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Type</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_type</font></div></td>
</tr>
<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Wep</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_wep</font></div></td>
</tr>
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Cloaked</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_cloaked</font></div></td>
</tr>
<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Carrier</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_carrier</font></div></td>
</tr>
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">First Seen</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_first</font></div></td>
</tr>
<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Last Seen</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_last</font></div></td>
</tr>
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Channel</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_channel</font></div></td>
</tr>
<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Maxrate</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_maxrate</font></div></td>
</tr>
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Packets (LLC)</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_packets_LLC</font></div></td>
</tr>
<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Packets (data)</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_packets_data</font></div></td>
</tr>
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Packets (crypt)</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_packets_crypt</font></div></td>
</tr>
<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Packets (weak)</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_packets_weak</font></div></td>
</tr>
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Packets (total)</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_packets_total</font></div></td>
</tr>
<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Datasize</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_datasize</font></div></td>
</tr>
EOM

	if ($net_clients_total > 0) {
    print HTML_NET_OUT <<EOM;
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Clients</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="$net_clients_link">$net_clients_total</a></font></div></td>
</tr>
EOM
	} else {
    print HTML_NET_OUT <<EOM;
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Clients</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_clients_total</font></div></td>
</tr>
EOM
}

    print HTML_NET_OUT <<EOM;
<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">GPS Min Lat</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_gps_min_lat</font></div></td>
</tr>
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">GPS Min Lon</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_gps_min_lon</font></div></td>
</tr>
<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">GPS Min Alt</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_gps_min_alt</font></div></td>
</tr>
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">GPS Min Spd</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_gps_min_spd</font></div></td>
</tr>

<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">GPS Max Lat</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_gps_max_lat</font></div></td>
</tr>
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">GPS Max Lon</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_gps_max_lon</font></div></td>
</tr>
<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">GPS Max Alt</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_gps_max_alt</font></div></td>
</tr>
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">GPS Max Spd</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_gps_max_spd</font></div></td>
</tr>
<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">IP Range</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_ip_range</font></div></td>
</tr>
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">IP Type</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_ip_type</font></div></td>
</tr>
<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Map Approx. Location:</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_gps_aprox_map_avilable</font></div></td>
</tr>

EOM

    if ($this_net_snort) {

        print HTML_NET_OUT <<EOM;
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Snort Output:</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="$net_snort_link">View Output</a></font></div></td>
</tr>
EOM

    }

    print HTML_NET_OUT <<EOM;
</table>
<br>
<hr align="center" width="680" size="1" noshade>
<div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="javascript:history.back(1)">&lt; back </a></font></div>
<br>
<br>
</body>
</html>
EOM
    close HTML_NET_OUT;


if (@net_clients) {


    open( HTML_CLIENT_OUT, ">$net_clients_link" );

    print HTML_CLIENT_OUT <<EOM;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>Kismet Log Viewer 1.0 - By Brian Hoy Jr. </title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>
<body leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="1024" border="0" align="center" cellpadding="5" cellspacing="1">
  <tr> 
    <td width="30%"><a href="$html_out_file"><img src="$logo_location" width="214" height="77" border="0"></a></td>
    <td width="70%" align="right" valign="top"><br><br><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><a href="$help_location">help</a> - <a href="$about_location">about</a> - <a href="$net_stats_link">stats</a><br></font></td>
  </tr>
</table>
EOM


    foreach $this_client (@net_clients) {

        $client_number = $this_client->getAttribute('number');
        $client_type   = $this_client->getAttribute('type');
        $client_wep    = $this_client->getAttribute('wep');
        $client_first  = $this_client->getAttribute('first-time');
        $client_last   = $this_client->getAttribute('last-time');
        $client_mac    =
          $this_client->getElementsByTagName('client-mac')
          ->[0]->getFirstChild->getData;
        $client_packets_data =
          $this_client->getElementsByTagName('client-data')
          ->[0]->getFirstChild->getData;
        $client_packets_crypt =
          $this_client->getElementsByTagName('client-crypt')
          ->[0]->getFirstChild->getData;
        $client_packets_weak =
          $this_client->getElementsByTagName('client-weak')
          ->[0]->getFirstChild->getData;
        $client_datasize =
          $this_client->getElementsByTagName('client-datasize')
          ->[0]->getFirstChild->getData;
        $client_maxrate =
          $this_client->getElementsByTagName('client-maxrate')
          ->[0]->getFirstChild->getData;

        if ( $temp = $this_client->getElementsByTagName('client-min-lat')->[0] )
        {
            $client_gps_min_lat =
              $this_client->getElementsByTagName('client-min-lat')
              ->[0]->getFirstChild->getData;
            $client_gps_min_lon =
              $this_client->getElementsByTagName('client-min-lon')
              ->[0]->getFirstChild->getData;
            $client_gps_min_alt =
              $this_client->getElementsByTagName('client-min-alt')
              ->[0]->getFirstChild->getData;
            $client_gps_min_spd =
              $this_client->getElementsByTagName('client-min-spd')
              ->[0]->getFirstChild->getData;
            $client_gps_max_lat =
              $this_client->getElementsByTagName('client-max-lat')
              ->[0]->getFirstChild->getData;
            $client_gps_max_lon =
              $this_client->getElementsByTagName('client-max-lon')
              ->[0]->getFirstChild->getData;
            $client_gps_max_alt =
              $this_client->getElementsByTagName('client-max-alt')
              ->[0]->getFirstChild->getData;
            $client_gps_max_spd =
              $this_client->getElementsByTagName('client-max-spd')
              ->[0]->getFirstChild->getData;
        }
        else {
            $client_gps_min_lat = "NA";
            $client_gps_min_lon = "NA";
            $client_gps_min_alt = "NA";
            $client_gps_min_spd = "NA";
            $client_gps_max_lat = "NA";
            $client_gps_max_lon = "NA";
            $client_gps_max_alt = "NA";
            $client_gps_max_spd = "NA";
        }

        if ( $temp =
            $this_client->getElementsByTagName('client-ip-address')->[0] )
        {
            $client_ip_address =
              $this_client->getElementsByTagName('client-ip-address')
              ->[0]->getFirstChild->getData;
            @client_ip_parts =
              $this_client->getElementsByTagName('client-ip-address');
            foreach $this_client_ip (@client_ip_parts) {
                $client_ip_type = $this_client_ip->getAttribute('type');
            }
        }
        else {
            $client_ip_address = "NA";
            $client_ip_type    = "NA";
        }

        if ( "$client_wep" eq "true" ) { $client_wep = "Y"; }
        else { $client_wep = "N"; }

        $client_device_name = "Type: NA";
        foreach $client_manuf_line (@client_manf) {
            chomp $client_manuf_line;
            @client_manuf_line_parts = split ( /\t/, $client_manuf_line );
            if ( $client_mac =~ /$client_manuf_line_parts[0]/ ) {
                $client_device_name =
"Type: $client_manuf_line_parts[1] $client_manuf_line_parts[2]";
            }
        }

        print
"KLV: Generating details for network #$net_number ($net_ssid) client #$client_number ...\n";

        print HTML_CLIENT_OUT <<EOM;
<table width="760" border="0" align="center" cellpadding="5" cellspacing="1" bgcolor="#efefef">
  <tr bgcolor="#cecece"> 
    <td width="200"> 
      <div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Client #$client_number</font></div></td>
    <td width="540"> 
      <div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$client_device_name (<a href="$net_link">$net_ssid</a>)</font></div></td>
  </tr>
<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Type</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$client_type</font></div></td>
</tr>
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Wep</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$client_wep</font></div></td>
</tr>
<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">First Seen</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$client_first</font></div></td>
</tr>
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Last Seen</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$client_last</font></div></td>
</tr>
<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Mac</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$client_mac</font></div></td>
</tr>
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Packets (data)</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$client_packets_data</font></div></td>
</tr>
<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Packets (crypt)</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$client_packets_crypt</font></div></td>
</tr>
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Packets (weak)</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$client_packets_weak</font></div></td>
</tr>
<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Packets (total)</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_packets_total</font></div></td>
</tr>
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Datasize</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$client_datasize</font></div></td>
</tr>
<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Maxrate</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$client_maxrate</font></div></td>

<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">GPS Min Lat</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$client_gps_min_lat</font></div></td>
</tr>
<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">GPS Min Lon</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$client_gps_min_lon</font></div></td>
</tr>
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">GPS Min Alt</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$client_gps_min_alt</font></div></td>
</tr>
<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">GPS Min Spd</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$client_gps_min_spd</font></div></td>
</tr>

<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">GPS Max Lat</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$client_gps_max_lat</font></div></td>
</tr>
<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">GPS Max Lon</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$client_gps_max_lon</font></div></td>
</tr>
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">GPS Max Alt</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$client_gps_max_alt</font></div></td>
</tr>
<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">GPS Max Spd</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$client_gps_max_spd</font></div></td>
</tr>
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">IP Address</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$client_ip_address</font></div></td>
</tr>
<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">IP Type</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$client_ip_type</font></div></td>
</tr>

</table>
<br>
EOM

    }    # end foreach client

    print HTML_CLIENT_OUT <<EOM;
</table>
<br>
<hr align="center" width="680" size="1" noshade>
<div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="javascript:history.back(1)">&lt; back </a></font></div>
<br>
<br>
</body>
</html>
EOM
    close HTML_CLIENT_OUT;

} # end of @net_clients


}    # end foreach @networks

print HTML_OUT <<EOM;
</table>
<br>
<hr align="center" width="680" size="1" noshade>

<div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color="#a5a5a5">
Started: $kismet_start_time - Ended: $kismet_end_time<br>
Log File: $file<br> 
</font></div>
<br><br>
<br><br>
<br><br>
<br><br>
<br><br>
<br><br>
<br><br>
<br><br>
<br><br>
<br><br>
<br><br>
<br><br>
<br><br>
<br><br>
<br><br>
<br><br>
<br><br>
<br><br>
<br><br>
</body>
</html>
EOM
close HTML_OUT;


print "KLV: Generating Stats...\n";

    open( HTML_STATS_OUT, ">$net_stats_link" );

    print HTML_STATS_OUT <<EOM;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>Kismet Log Viewer 1.0 - By Brian Joy Jr. </title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>
<body leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="760" border="0" align="center" cellpadding="5" cellspacing="1">
  <tr> 
    <td width="30%"><a href="$html_out_file"><img src="$logo_location" width="214" height="77" border="0"></a></td>
    <td width="70%" align="right" valign="top"><br><br><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><a href="$help_location">help</a> - <a href="$about_location">about</a> - <a href="$net_stats_link">stats</a><br></font></td>
  </tr>
</table>
<table width="760" border="0" align="center" cellpadding="5" cellspacing="1" bgcolor="#efefef">
  <tr bgcolor="#cecece"> 
    <td width="200"> 
      <div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Stats:</font></div></td>
    <td width="540"> 
      <div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$file</font></div></td>
  </tr>

<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Started</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$kismet_start_time</font></div></td>
</tr>
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Ended</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$kismet_end_time</font></div></td>
</tr>

<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Kismet Server Ver</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$kismet_ver</font></div></td>
</tr>
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Total Networks</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$total_networks</font></div></td>
</tr>
<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Total Networks with WEP</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$total_wep</font></div></td>
</tr>
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Total Networks without WEP</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_total_unwep</font></div></td>
</tr>
<tr  bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">% Networks with WEP</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_percent_wep%</font></div></td>
</tr>
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Total Networks Factory Default</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$total_factory_defaults</font></div></td>
</tr>
<tr  bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">% Networks Factory Default</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_percent_factory_default%</font></div></td>
</tr>
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Total Cloaked Networks</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$total_cloaked</font></div></td>
</tr>
<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">% Networks Cloaked</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$net_percent_cloaked%</font></div></td>
</tr>
<tr>
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Total Clients</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$total_clients</font></div></td>
</tr>
<tr bgcolor="#FFFFFF">
<td width="200"><div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Total Packets</font></div></td>
<td width="540"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$total_packets</font></div></td>
</tr>

</table>
<br>
<hr align="center" width="680" size="1" noshade>
<div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="javascript:history.back(1)">&lt; back </a></font></div>
<br>
</body>
</html>
EOM

print "KLV: Done!\n";
exit;

sub do_snort {

    $snort_file = $file;
    $snort_file =~ s/\.xml/\.dump/g;

    system("snort -vdeCr $snort_file > snort_temp.txt");

    open( SNORTFILE, "snort_temp.txt" );
    @all_snort_lines = <SNORTFILE>;
    close SNORTFILE;
    unlink("snort_temp.txt");

    foreach $this_line (@all_snort_lines) {
        $all_lines_comb .= "$this_line";
    }

    @all_snort_line_parts = split (
/\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+\=\+/,
        $all_lines_comb
    );

    foreach $this_line (@all_snort_line_parts) {

        undef $this_packets_lines;
        undef $bssid;

        @this_packet_lines = split ( /\n/, $this_line );

        foreach $this_packet_line (@this_packet_lines) {

            if ( $this_packet_line =~ /Run time for packet processing was/ ) {
                break;
            }

            if ( $this_packet_line =~ /bssid/ ) {
                @this_bssid_parts = split ( / /, $this_packet_line );
                $bssid = "$this_bssid_parts[1]";
            }
            $this_packet_line =~ s/\r/\<br\>/g;

            if ( $this_packet_line =~
                /No run mode specified, defaulting to verbose mode/g )
            {
                $this_packet_line = "<br>";
            }
            $this_packets_lines .= "$this_packet_line<br>";
        }

        if ($bssid) {

            @bssid_parts = split ( /\:/, $bssid );

            undef $this_full_bssid;

            foreach $this_bssid_parts (@bssid_parts) {

                if ( length($this_bssid_parts) < 2 ) {
                    $this_bssid_parts = "0" . "$this_bssid_parts";
                }

                $this_full_bssid .= "$this_bssid_parts";
            }

            $network_packets{"$this_full_bssid"} .= "$this_packets_lines";

        }

    }

}    # end sub do_snort

sub gen_snort($mod_bssid) {

    $net_snort_link =
      "$file" . "-kismet-log-view-" . "$mod_bssid" . "-snort.html";

    open( HTML_SNORT_OUT, ">$net_snort_link" );

    print HTML_SNORT_OUT <<EOM;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>Kismet Log Viewer 1.0 - By Brian Koy Jr. </title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>
<body leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="760" border="0" align="center" cellpadding="5" cellspacing="1">
  <tr> 
    <td width="30%"><a href="$html_out_file"><img src="$logo_location" width="214" height="77" border="0"></a></td>
    <td width="70%" align="right" valign="top"><br><br><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><a href="$help_location">help</a> - <a href="$about_location">about</a> - <a href="$net_stats_link">stats</a><br></font></td>
  </tr>
</table>
<table width="760" border="0" align="center" cellpadding="5" cellspacing="1" bgcolor="#efefef">
  <tr bgcolor="#cecece"> 
    <td width="760"> 
      <div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Snort output for:  <a href="$net_link"> $net_ssid</a> ($net_bssid)</font></div></td>
  </tr>
<tr bgcolor="#FFFFFF">
<td><font size="1" face="Verdana, Arial, Helvetica, sans-serif">
EOM

    print HTML_SNORT_OUT $network_packets{"$mod_bssid"};

    print HTML_SNORT_OUT <<EOM;
</font>
</td>
</tr>
</table>
<br>
</table>
<br>
<hr align="center" width="680" size="1" noshade>
<div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="javascript:history.back(1)">&lt; back </a></font></div>
<br>
<br>
</body>
</html>
EOM
    close HTML_SNORT_OUT;

}    #end sub gen_snort
