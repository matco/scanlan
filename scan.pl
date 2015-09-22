#!/usr/bin/perl
use strict;

use Config::Tiny;
use Net::Ping::External qw(ping);

#netmask regexp
my $netmask_regexp =~ /((\d{1,3}|\*)\.){3}(\d{1,3}|\*)/;

#configuration
my $config = Config::Tiny->read("config.ini", "utf8");

my $netmask = @ARGV[0];

if(!$netmask) {
	print "Netmask is required";
	exit
}

if(!$netmask =~ $netmask_regexp) {
	print "Netmask is invalid";
	exit
}

scan($netmask);

my @hosts;

sub scan {
	my $ip = $_[0];
	my $ping = Net::Ping->new("icmp");

	my @date = gmtime(time);
	print "Start scan $date[3]/$date[4]/$date[5] a $date[2]:$date[1]:$date[0]\n";

	my @ip = split /\./, $ip;
	print "Splitted netmask : $ip[0]:$ip[1]:$ip[2]:$ip[3]\n";

	for(my $k = 0; $k < 4; $k++) {
		#test if netmask segment is a star
		if($ip[$k] eq '*') {
			#try all ip matching netmask
			for(my $i = 1; $i < 254; $i++) {
				$ip = "";
				$ip = ($k eq 0) ? $ip.$i.'.' : $ip.$ip[0].'.';
				$ip = ($k eq 1) ? $ip.$i.'.' : $ip.$ip[1].'.';
				$ip = ($k eq 2) ? $ip.$i.'.' : $ip.$ip[2].'.';
				$ip = ($k eq 3) ? $ip.$i : $ip.$ip[3];
				print $ip."...";
				if($ping->ping($ip, 1)) {
					push(@hosts, $ip);
					print "ok";
				}
				else {
					print "not reachable";
				}
				print "\n";
			}
		}
	}
	print "Found scalar(@hosts) hosts\n";

	$ping->close();
	return @hosts;
}

sub try_connection {
	my $ip = $_[0];
	my $port = $_[1];
	#TODO
	#try to connect to the host on the specified port
}

sub save_hosts {
	#database connection
	my $db = DBI->connect(
		"DBI:mysql:database=$config->{database}->{name};host=$config->{database}->{host};port=$config->{database}->{port}",
		$config->{database}->{user},
		$config->{database}->{password}
	) or die "\nUnable to connect with $config->{database}->{host}:$config->{database}->{port}";

	foreach my $host (@hosts) {
		$db->do("INSERT INTO hosts (name) VALUES ($host)");
	}
	$db->disconnect();
}
