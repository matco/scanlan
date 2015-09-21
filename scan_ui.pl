#!/usr/bin/perl
use Net::Ping::External qw(ping);
use Tk;
use Tk::Balloon;

$fenetre = new MainWindow();
$fenetre->title('SCLan');
$fenetre->minsize('250','150');

$titre = $fenetre->Label(-text => 'SCLan');
$titre->pack(-fill => 'x');

$choix = $fenetre->Frame();
$choix->pack();

$mode = $choix->Label(-text => 'Mode de balayage : ');
#$mode->pack(-side => 'left');

#$mode_auto = $choix->Radiobutton(-text => 'Automatique',-value => '1',-variable => \$mode_choix);
#$mode_balayage = $choix->Radiobutton(-text => 'Balayage',-value => '2',-variable => \$mode_choix);
#$mode_auto->pack();
#$mode_balayage->pack();

$mode = $fenetre->Optionmenu(
	-command=> sub {print "$le_choix \n" ;},
	-textvariable=> \$mode_choix,
	-options=>[
		'Automatique',
		'Balayage' ,
	]
);

$mode->pack ( ) ;


#$mode_auto_aide = $choix->Balloon();
#$mode_auto_aide->attach($mode_auto,-balloonmsg => 'Tente d\'utiliser les fonctions systemes pour reperer les machines',-state => 'balloon');
#$mode_balayage_aide = $choix->Balloon();
#$mode_balayage_aide->attach($mode_balayage,-balloonmsg => 'Balaie une plage d\'adresse',-state => 'balloon');

MainLoop();
