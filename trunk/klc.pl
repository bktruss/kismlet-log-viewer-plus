#!/usr/bin/perl
##########################################################################################################
#
# Kismet Log Combiner (part of Kismet Log Viewer) - By Brian Foy Jr. - 3/26/2003
#
# Takes multiple Kismet .xml log files and Outputs one new .xml file with the networks renumbered.
#
# Requires: 
# At leaast two Kismet .xml logfiles.
#
# To Use:
# ./klc.pl Kismet-Log1.xml Kismet-Log2.xml Kismet-Log3.xml New-Kismet-Comb-Log.xml
# ./klc.pl *.xml New-Kismet-Comb-Log.xml
# ./klc.pl ./klc.pl *.xml.gz New-Kismet-Comb-Log.xml
#
#	Optional:
#	If you have the .dump files for the .xml files and also want to combine those, you can 
#	add -dump to the end. This will create a .dump file with the same output name.
# 	Example:
#	./klc.pl *.xml New-Kismet-Comb-Log.xml -dump
#
##########################################################################################################

my $have_zlib = 0;
if ( eval "require Compress::Zlib" ) {
 	$have_zlib = 1;                   
}

if (@ARGV < 2) {
  	print "Usage: $0 <list> <of> <log> <files> <to> <combine> output-file-name.xml [-dump]\n";
  	exit;
}


$check_for_dump = pop @ARGV;

if ( "$check_for_dump" eq "-dump" ) {
$out_file_name = pop @ARGV;
$do_dump = 1;
print "got dump\n";
} else {
$out_file_name = $check_for_dump;
}

@log_files = @ARGV;

if ($do_dump) {

# mergecap -w out.dump test.dump test2.dump
$dump_out_file_name = $out_file_name;
$dump_out_file_name =~ s/\.xml/\.dump/g;
$run_merge_cap = "mergecap -w $dump_out_file_name ";
@dump_files = @log_files;

	foreach $this_dump_file (@dump_files) {
	$this_dump_file =~ s/\.xml/\.dump/g;
	$run_merge_cap .= "$this_dump_file ";
	}

print "Merging .dump files using: $run_merge_cap\n";
system ("$run_merge_cap");
}

  
$x = 0;

foreach $this_log (@log_files) {

print "Reading in $this_log...\n";

undef @this_log_lines;
if ( $this_log =~ /.gz$/ ) {
	die "Can't read $this_log without Compress::Zlib" unless $have_zlib;
	my $gz = Compress::Zlib::gzopen($this_log,'r');
	my $line;
	while ( $gz->gzreadline($line) != 0 ) {
		push @this_log_lines, $line;
	}
	$gz->gzclose;
} else {
	open(LOG_FILE, "$this_log");
	@this_log_lines = <LOG_FILE>;
	close(LOG_FILE);
}

foreach $this_line (@this_log_lines) {
$add_line = $this_line;

if ($this_line=~/<wireless-network number="\d\d"/) {
$x++;
$add_line =~ s/<wireless-network number="\d\d"/<wireless-network number="$x"/;
} elsif ($this_line=~/<wireless-network number="\d"/) {
$x++;
$add_line =~ s/<wireless-network number="\d"/<wireless-network number="$x"/;
}
push (@new_lines, $add_line);
} # end foreach $this_line
} # end foreach $this_log

print "Writing out $out_file_name...\n";

open(OUT_FILE,">$out_file_name");
foreach $out_line (@new_lines) {

if ($out_line=~/<?xml/) {
print OUT_FILE ("$out_line") unless ($xml_start);
$xml_start = 1;
}
elsif ($out_line=~/<!DOCTYPE/) {
print OUT_FILE ("$out_line") unless ($doc_start);
$doc_start = 1;
}
elsif ($out_line=~/<detection-run/) {
print OUT_FILE ("$out_line") unless ($run_start);
$run_start = 1;
}
elsif ($out_line=~/<\/detection-run/) {
}
elsif ($out_line =~/^\n/) {
}
else {
print OUT_FILE ("$out_line"); 
}
} # end foreach $out_line
print OUT_FILE ("<\/detection-run>\n");
close(OUT_FILE);
