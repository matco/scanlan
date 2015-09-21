package AbstractListing::FTP;

use Net::FTP;

sub new {
	my $self = {};
	$self->{HOST} = $_[0];
	$self->{PORT} = $_[1];
	$self->{USER} = $_[2];
	$self->{PASSWORD} = $_[3];

	bless($self);
	return $self;
}

sub init {
	my $self = shift;
	print "Connecting to FTP...";
	$self->{CONNECTION} = Net::FTP->new($self{HOST},Port => $self{PORT},Debug => 0) or die "\nUnable to connect to $self{HOST}:$self{PORT} : $@";
	$self->{CONNECTION}->login($self{USER},$self{PASSWORD}) or die "\nUnable to login : $self->{CONNECTION}->message";
	print "Ok\n";
	return 0;
}

sub setPath {
	if( $_[0] && !$_[1]) {
		$self->{PATH} = $_[0];
		return 0;
	}
	else {
		return 1;
	}
}

sub getPath {
	return $self->{PATH};
}

sub list {
	if($_[0] && $_[1]) {
		$path = $_[0];
		my $self = shift;
		my @results;
		$self->{CONNECTION}->cwd($path);
		my @files = $self->{CONNECTION}->dir() or die "Unable to list directory : $self->{CONNECTION}->message";
		foreach $file (@files) {
			my @properties = $file =~ /([-d])([rwxst-]{9}) .* (\d+) (\w+ \d+ \d{2}:\d{2}) (.+)/;
			if($properties[4] ne "." && $properties[4] ne "..") {
				my @extension = $properties[4] =~ /\.([^\.]*$)/;
				my %result = ("name", $properties[4], "extension", @extension[0], "size", $properties[2]);
				if($properties[0] eq "d") {
					$result{"folder"} = 1;
				}
				@results = (@results, [%result]);
			}
		}
		return @results;
	}
	return -1;
}

sub addFolderToPath {
	return "$_[0]/$_[1]/"
}

sub end {
	my $self = shift;
	if($self->{CONNECTION}) {
		$self->{CONNECTION}->quit();
	}
}

sub DESTROY {
	end();
}

1;
