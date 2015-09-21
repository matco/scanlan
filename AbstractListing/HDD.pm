package AbstractListing::HDD;

use IO::Dir;

sub new {
	my $self = {};
	bless($self);
	return $self;
}

sub init {
	return 0;
}

sub list {
	if($_[0] && $_[1]) {
		$path = $_[1];
		my $self = shift;
		my @resutats;
		@results = ();
		my $list = IO::Dir->new($path);
		if(!defined($list)) {
			die "\n$path is not a valid path";
		}
		while(defined($name = $list->read)) {
			if($name ne "." && $name ne "..") {
				my @extension = $name =~ /\.([^\.]*$)/;
				my $folder = (-d "$path/$name" ) ? 1 : 0;
				my $size = -s "$path/$name";
				my %result = ("name" => $name, "extension" => @extension[0], "folder" => $folder, "size" => $size);
				push(@results,{%result});
			}
		}
		return @results;
	}
	return -1;
}

sub getHost {
	return `hostname`;
}

sub addFolderToPath {
	return "$_[1]/$_[2]";
}

sub end {
	my $self = shift;
}

sub DESTROY {
	end();
}

1;