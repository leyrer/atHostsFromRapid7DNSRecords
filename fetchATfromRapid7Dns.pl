#!/usr/bin/perl 

# Fetches the most recent list of hosts ending in '.at' from the Project Sonar Forward DNS dataset 
# See https://github.com/rapid7/sonar/wiki/Forward-DNS
# Need curl, zcat, ... or similar to actually fetch the ~13GB of data

use strict;
use warnings;
use v5.10.0;
use Data::Dumper;
use JSON;
use LWP::UserAgent qw( );
use URI::Escape    qw( uri_escape );

# modify here START
my $fetchcmd = 'curl -s §url§ | zcat | cut -d \',\' -f 1 | grep \'.at$\' > athosts_§DATE§.txt';
my $DEBUG = 0;
my $timestampfile = './rapid7dns.timestamp';
my $jsonurl = 'https://scans.io/json';
#modify here STOP

my $ua = LWP::UserAgent->new('agent' => 'fetchAT/1.0');
my $response = $ua->get($jsonurl);

if (not $response->is_success()) {
	die( "Couldn't fetch >$jsonurl<. Reason: " . $response->status_line() );
}

my $json = $response->decoded_content;

my $data = decode_json $json;
my $studies = $data->{studies};
foreach my $study (@$studies) {
	if( $study->{name} eq 'DNS Records (ANY)' ) {
		my $dns_records = $study;
		my $files = $dns_records->{files};
		my $timestamp = getLastUpdate($timestampfile);
		my $workfile = getMostRecentFile($files, $timestamp);
		if( defined $workfile) {
			$timestamp = $workfile->{'updated-at'};
			$fetchcmd =~ s/§url§/$workfile->{name}/;
			$fetchcmd =~ s/§DATE§/$timestamp/;
			say "Starting working on $fetchcmd ...";
			system($fetchcmd);
			say "Finished!"
		} else {
			say "No updates since $timestamp." if($DEBUG);
		}
		writeLastUpdate($timestampfile, $timestamp);
		last;
	}
}

exit;

sub getMostRecentFile {
	my ($filesarray, $ts) = @_;
	my $most_recent = undef;
	foreach my $file (@$filesarray) {
		if( $ts lt $file->{'updated-at'}) {	# ISO 88591 dates can be compared via string operations :D
			$ts = $file->{'updated-at'};
			$most_recent = $file;
		}
	}
	return($most_recent);
}

sub getLastUpdate {
	my ($tsf) = @_;
	my $ts = "";
	if( not (open TS, '<', $tsf) ) {
		warn "Timestampfile '$tsf' not found. reason: $!" if($DEBUG);
		return("");
	};
	$ts = <TS>;
	$ts = "" if(not defined $ts);
	warn "Timestamp: $ts|" if($DEBUG);
	close(TS);
	return($ts);
}

sub writeLastUpdate {
	my ($tsf, $tsv) = @_;
	if( not (open TS, '>', $tsf) ) {
		warn "Timestampfile '$tsf' not written. reason: $!" if($DEBUG);
	};
	print TS "$tsv";
	close(TS);	
}
