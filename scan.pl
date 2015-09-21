#!/usr/bin/perl
use Net::Ping::External qw(ping);

#configuration
my $config = Config::Tiny->read("config.ini", "utf8");

#system 'cls';
print "*****************************\n";
print "********    SCLan    ********\n";
print "*****************************\n";
print "Mode de scan\n";
print " 1. Automatique\n";
print " 2. Balayage\n";
do {
	print "Entrer le choix : ";
	$choix = <STDIN>;
	chomp($choix);
}
while($choix ne '1' and $choix ne '2');

#scan en mode automatique
if($choix eq '1') {
	reseau_auto();
}
#scan en mode balayage
elsif($choix eq '2') {
	do {
		print "Masque d'IP (*.*.*.*) : ";
		$ip = <STDIN>;
		chomp($ip);
	}
	while (!verifip($ip));
	reseau_balayage($ip);
}

#fonctions :
sub reseau_auto {
	#renvoie la liste des machines presentes sur le reseau a partir de la commande net view de windows
	#retour de la fonction net view
	$machines = `net view`;
	@machines = $machines =~ /\\\\((?:\w|\-)*)\b/g;
	#print "Resultat de la commande net view : @machines";
	foreach $machine (@machines) {
		print "$machine\n";
	}
	return @machines;
}

sub reseau_balayage {
	my $ip = $_[0];
	#instanciantion de l'objet
	$ping = Net::Ping->new();
	#renvoie la liste des machines presentes sur le reseau en balayant une a une toutes les ip de la plage parametre
	@date = gmtime(time);
	print "Scan commence le $date[3]/$date[4]/$date[5] a $date[2]:$date[1]:$date[0]\n";
	@ip = split /\./, $ip;
	print "IP decompose : $ip[0]:$ip[1]:$ip[2]:$ip[3]\n";
	#pour chaque partie de l'IP
	for($k = 0; $k < 4; $k++) {
		#test si la partie de l'IP courante est une *
		if($ip[$k] eq '*') {
			#parcours de toute les adresses de la plage masquee
			for($i = 1; $i < 254; $i++) {
				$ip = "";
				$ip = ($k eq 0) ? $ip.$i.'.' : $ip.$ip[0].'.';
				$ip = ($k eq 1) ? $ip.$i.'.' : $ip.$ip[1].'.';
				$ip = ($k eq 2) ? $ip.$i.'.' : $ip.$ip[2].'.';
				$ip = ($k eq 3) ? $ip.$i : $ip.$ip[3];
				print $ip."...";
				if($ping->ping($ip,1)) {
					push(@machines,$ip);
					print "ok";
				}
				else {
					print "introuvable";
				}
				print "\n";
			}
		}
	}
	print "scalar($machines) machine(s) decouverte(s)\n";
	#destruction de l'objet
	$ping->close();
	return @machines;
}


sub verifip {
	my $ip = $_[0];
	return $ip =~ /((\d{1,3}|\*)\.){3}(\d{1,3}|\*)/;
}

sub connecte {
	my $ip = $_[0];
	my $port = $_[1];
	#tentative de connexion sur l'ip et le port parametre
}

sub enregistre {
	#database connection
	my $db = DBI->connect(
		"DBI:mysql:database=$config->{database}->{name};host=$config->{database}->{host};port=$config->{database}->{port}",
		$config->{database}->{user},
		$config->{database}->{password}
	) or die "\nUnable to connect with $config->{database}->{host}:$config->{database}->{port} : $db->errstr";

	foreach $machine (@machines) {
		$db->do("INSERT INTO hosts (name) VALUES ($machine)");
	}
	$db->disconnect();
}
