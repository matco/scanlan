use Tk ;

# Programme principal

$fenetre = new MainWindow();
$fenetre -> title("SCLan" );

$barre_menu = $fenetre->Frame(
	-relief => 'groove',
	-borderwidth => 2
);

$menu = $barre_menu->Menubutton(
	-text => 'Application',
	-font => '{Verdana} 10',
	-tearoff => 0 ,
	-menuitems => [
		['command' => 'Quitter' ,
			-font => '{Verdana} 10',
			-command => \&Quitter 
		]
	]
);

$menu->pack(-side => 'left');


$barre_menu->pack(
	-side => 'top',
	-anchor => 'n', -fill => 'x'
);

$fenetre->Label(
	-text => "Mode de scan" ,
	-font => '{Verdana} 10',
)->pack(
	-anchor => 'ne', 
	-fill => 'x'
);

$barre_statut = $fenetre->Label(
	-relief => 'groove',
	-font => '{Verdana} 10'
);


$barre_statut->pack(
	-side => 'bottom',
	-fill => 'both'
);


MainLoop();


sub Quitter {
	exit(0);
}