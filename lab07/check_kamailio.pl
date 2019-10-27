#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use utils qw($TIMEOUT %ERRORS &usage &support &print_revision);
use XMLRPC::Lite;

# Globals
our $VERSION = 0.1;

our (
	$opts_host,
	$opts_hostname,
	$opts_port,
	$opts_verbose,
	$opts_cacti,
	$cacti_values,
    );

my $cfgpath = '/etc/icinga/objects/';

# main begins
{

	# Declarations
	my (	$opts_help,
		$opts_version,
		$opts_tcp,
		$opts_memwarn,
		$opts_memcrit,
		$opts_tcpwarn,
		$opts_tcpcrit,
	   );

	# Get options
	Getopt::Long::Configure ("bundling");
	GetOptions(
			'c|cacti'  => \$opts_cacti,
			'h|help|?'  => \$opts_help,
			'H|host=s'  => \$opts_host,
			'hostname=s' => \$opts_hostname,
			'memcrit=i'  => \$opts_memcrit,
			'memwarn=i'  => \$opts_memwarn,
			'P|port=s'  => \$opts_port,
			't|tcp'     => \$opts_tcp,
			'tcpcrit=i'  => \$opts_tcpwarn,
			'tcpwarn=i'  => \$opts_tcpcrit,
			'v|verbose' => \$opts_verbose,
			'V|version' => \$opts_version,
	);

	if ($opts_version) {

		printver();
		exit $ERRORS{'OK'};

	} elsif ($opts_help) {

		print_help();
		exit $ERRORS{'OK'};
	}

	if (!$opts_host ) {
		print_help();
		exit $ERRORS{'UNKNOWN'};
	}
	if (!$opts_hostname) {
		$opts_hostname = $opts_host;
	}
	$opts_port ||= 5060;
	$opts_memwarn ||= 80;
	$opts_memcrit ||= 90;
	$opts_tcpwarn ||= 80;
	$opts_tcpcrit ||= 90;

	my @msgs = ();
	my ($checkmsg,$checkstate,$state,$msg) = '';
	$state = 'OK';
	my $failcount = 0;

	# First check for Mem Usage
	($checkmsg,$checkstate) = check_memory($opts_memwarn,$opts_memcrit);

	($state,$msg,$failcount,@msgs) = evaluate_res($state,$checkmsg,$checkstate,$failcount,@msgs) unless ($opts_cacti);

	# Check for TCP Connections if enabled
	if ($opts_tcp) {
		($checkmsg,$checkstate) = check_tcpconnections($opts_tcpwarn,$opts_tcpcrit);

		($state,$msg,$failcount,@msgs) = evaluate_res($state,$checkmsg,$checkstate,$failcount,@msgs) unless ($opts_cacti);
	}

	($checkmsg, $checkstate) = check_version();

	($state,$msg,$failcount,@msgs) = evaluate_res($state,$checkmsg,$checkstate,$failcount,@msgs) unless ($opts_cacti);

	if ($opts_cacti) {
		$cacti_values =~ s/\s*$//;
		print $cacti_values;
	} else {
		# Exit with the correct Errorcode
		print $msg;
		exit $ERRORS{$state};
	}

}

sub evaluate_res {
	my ($state,$m,$s,$f,@ms) = @_;
	my $msg;
	$state ||= 'OK';
	$f++ if ($s ne "OK");
	if ($state eq "CRITICAL") {
		# do nothing
		$state = "CRITICAL";
	} elsif ($state eq "UNKNOWN") {
		$state = $s if ($s eq "CRITICAL");
	} elsif ($state eq "WARNING") {
		$state = $s if ($s eq "CRITICAL");
	} elsif ($state eq "OK") {
		$state = $s;
	}
	push(@ms, $m) if ($m);
	if ($state ne "OK") {
		if (@ms > 1) {
			$msg = sprintf("%s: %d of %d Tests failed.\n",$state, $f, scalar(@ms));
			foreach (@ms) {
				$msg .= $_."\n";
			}
		} else {
			$msg = "$state: $ms[0]";
		}
	} else {
		if (@ms > 1) {
			$msg = sprintf("%s: All %d Tests OK.\n",$state, scalar(@ms));
			foreach (@ms) {
				$msg .= $_."\n";
			}
		} else {
			$msg = "$state: $ms[0]";
		}
	}
	return($state,$msg,$f,@ms);
}

sub check_memory {

# Example output:
#max_used: 2765872
#free: 64342992
#real_used: 2765872
#used: 2534472
#fragments: 20
#total: 67108864

	my ($warn,$crit) = @_;
	my (%r,$k);
	my ($total_mem,$used_mem,$msg,$state);
	my $method = "core.shmmem";
	my @rpc_params = ();
	my $res = call_rpc($method,@rpc_params);
	if (ref($res) eq "HASH"){
		%r=%{$res};
		foreach $k (keys %r) {
			$total_mem = $r{$k} if ($k eq "total");
			$used_mem = $r{$k} if ($k eq "used");
		}
		print "MemCheck: Got Total Mem '$total_mem' and Used Mem '$used_mem'\n" if ($opts_verbose);
		my $usedpct = $used_mem * 100 / $total_mem;
		if ($opts_cacti) {
			$cacti_values .= sprintf("mem_total:%d mem_used:%d mem_pct:%.2f ", $total_mem, $used_mem, $usedpct);
		} else {
			if ($used_mem * 100 > $total_mem * $crit) {
				$msg = sprintf("Memory: %.2f > %d%% (%d of %d used)", $usedpct, $crit, $used_mem, $total_mem);
				$state = "CRITICAL";
			} elsif ($used_mem * 100 > $total_mem * $warn) {
				$msg = sprintf("Memory: %.2f > %d%% (%d of %d used)", $usedpct, $warn, $used_mem, $total_mem);
				$state = "WARNING";
			} else {
				$msg = sprintf("Memory: %.2f%% used (%d of %d)", $usedpct, $used_mem, $total_mem);
				$state = "OK";
			}
		}
	} else {
		print "Unexpected response when querying Mem Stats";
		exit $ERRORS{'UNKNOWN'};
	}
	return($msg,$state);
}

sub check_tcpconnections {

# Example output:
#readers: 8
#max_connections: 16384
#opened_connections: 2
#write_queued_bytes: 0

	my ($warn,$crit) = @_;
	my (%r,$k);
	my ($max_conn,$open_conn,$msg,$state);
	my $method = "core.tcp_info";
	my @rpc_params = ();
	my $res = call_rpc($method,@rpc_params);
	if (ref($res) eq "HASH"){
		%r=%{$res};
		foreach $k (keys %r) {
			$max_conn = $r{$k} if ($k eq "max_connections");
			$open_conn = $r{$k} if ($k eq "opened_connections");
		}
		print "TCPCheck: Got Max Connections '$max_conn' and Open Connections '$open_conn'\n" if ($opts_verbose);
		my $connpct = $open_conn * 100 / $max_conn;
		if ($opts_cacti) {
			$cacti_values .= sprintf("tcp_max:%d tcp_used:%d tcp_pct:%.2f ", $max_conn, $open_conn, $connpct);
		} else {
			if ($open_conn * 100 > $max_conn * $crit) {
				$msg = sprintf("TCP Connections: %.2f > %d%% (%d of %d used)",$connpct, $crit, $open_conn, $max_conn);
				$state = "CRITICAL";
			} elsif ($open_conn * 100 > $max_conn * $warn) {
				$msg = sprintf("TCP Connections: %.2f > %d%% (%d of %d used)",$connpct, $warn, $open_conn, $max_conn);
				$state = "WARNING";
			} else {
				$msg = sprintf("TCP Connections: %.2f%% used (%d of %d)", $connpct, $open_conn, $max_conn);
				$state = "OK";
			}
		}
	} else {
		print "Unexpected response when querying TCP Stats";
		exit $ERRORS{'UNKNOWN'};
	}
	return($msg,$state);
}

sub check_version {
	my $method = "core.version";
	my @rpc_params = ();
	my $res = call_rpc($method,@rpc_params);
	# Example output: 'kamailio 4.1.3 (x86_64/linux) '
	$res =~ /^kamailio ([0-9\.]+)/;
	my $version = $1;

	my $filename = '';
	if (-e "$cfgpath/versions/kamversion-$opts_hostname.txt") {
		$filename = "$cfgpath/versions/kamversion-$opts_hostname.txt";
	} else {
		$filename = "$cfgpath/versions/kamversion.txt";
	}
	my $wanted_version = undef;
	my $state = 'CRITICAL';
	my $msg = "Lorem Ipsum";
	if (!(-e $filename)) {
		$state = 'UNKNOWN';
		$msg = "Reference Version file missing!";
	} else {
		open(FILE, $filename);
		while (<FILE>) {
			$wanted_version = $_;
			chomp $wanted_version;
		}
		close(FILE);
		if (!$wanted_version) {
			$state = 'UNKNOWN';
			$msg = "UNKNOWN KAMAILIO Version";
		}
		elsif ($version eq $wanted_version) {
			$state = 'OK';
			$msg = "Version: $version";
		}
		else {
			$state = "WARNING";
			$msg = "Version is $version (wanted: $wanted_version)";
		}
	}
	return($msg,$state);
}

sub call_rpc {
	my ($method,@rpc_params) = @_;
	my (%r,$k);

	my($rpc_call) = XMLRPC::Lite
		-> proxy("http://$opts_host:$opts_port") -> call($method, @rpc_params);

	my $res= $rpc_call->result;

	if (!defined $res){
		print "Error querying Kamailio\n";
		$res=$rpc_call->fault;
		%r=%{$res};
		foreach $k (sort keys %r) {
			print("\t$k: $r{$k}\n");
		}
		exit $ERRORS{'UNKNOWN'};
	} else {
		return($res);
	}
}

sub alarmhandler {

	print "Plugin timed out!\n";
	exit $ERRORS{'WARNING'};
}

sub diehandler {

	my $result=shift;
	print "Check failed: $result\n";
	exit $ERRORS{'UNKNOWN'};
}

sub printusage {

	print "\nUsage: check_kamailio.pl [-hVv?t] -H hostname -p port\n";
}

sub printver {

	print_revision("check_kamailio.pl", "$VERSION");

}

sub print_help {

	printver();
	print "Copyright (c) 2009 sipgate GmbH\n\n";
	printusage();

	print <<TEXT;

options:

	-c, --cacti:		Cacti Mode. Returns Values only.

	-h, --help:		Print Usage Information.

	-H, --host:		The Hostname or IP of Kamailio server.

	--memcrit:		Critical Percentage for Memory Usage.

	--memwarn:		Warning Percentage for Memory Usage.

	-P, --port:		Port where Kamailio listens to TCP.

	-t, --tcp:		Check for TCP Connections, too.

	--tcpcrit:		Critical Percentage for TCP Connections

	--tcpwarn:		Warning Percentage for TCP Connections

	-v, --verbose:		Be verbose, print Check output.

	-V, --Version:		Version info.

TEXT
support();
}

