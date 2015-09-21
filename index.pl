#!/usr/bin/perl
use strict;

use Config::Tiny;
use Getopt::Long;
use DBI;
use URI;
use URI::File;

use AbstractListing::HDD;
use AbstractListing::FTP;

@INC = (@INC, ".");

#URI regexp
my $uri_regexp =~ m|(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?|;

#retrieve parameter
my $parameter = @ARGV[0];

if(!$parameter) {
	print "Path or URI is required";
	exit
}

#create URI object
my $uri;
#if parameter is a local path, transform it to an URI to normalize parameter management
if(!$parameter =~ $uri_regexp) {
	$uri = URI::file->new($parameter, "unix");
}
else {
	$uri = URI->new($parameter);
}

#retrieve options

#options used to filter files (warning, filters are cumulative)
#extensions filter
my @filter_extensions;
GetOptions ("extension=s" => \@filter_extensions);
#types filter
my @filter_types;
GetOptions ("type=s" => \@filter_types);

#indexation path
my $path = $uri->path;
print $path;

#other options
my $approximation = 0.05;
GetOptions("a=i" => \$approximation);

my $check_for_duplicate = 1;
GetOptions("-d" => \$check_for_duplicate);

#variable initialization
my $number_files = 0;
my $number_indexed_files = 0;
my $number_duplicates = 0;

my @all_files;
my $host_id = 1;

#configuration
my $config = Config::Tiny->read("config.ini", "utf8");

#database connection
print "Opening database connection...";
my $db = DBI->connect(
	"DBI:mysql:database=$config->{database}->{name};host=$config->{database}->{host};port=$config->{database}->{port}",
	$config->{database}->{user},
	$config->{database}->{password}
) or die "\nUnable to connect with $config->{database}->{host}:$config->{database}->{port} : $db->errstr";

print "Ok\n";

#extension listing
print "Retrieving extensions...";
my $query = $db->prepare("SELECT extension, type FROM extensions") or die "\nUnable to query extensions list : $db->errstr";
$query->execute();
my %types;
while(my @type = $query->fetchrow_array()) {
	$types{$type[0]} = $type[1];
}
print "Ok\n";

#create good indexer according to URI
my $indexer = factory($uri);
$indexer->init();

my $query_charset = $db->prepare("SET NAMES 'utf8'") or die "\nUnable to set utf-8 charset : $db->errstr";
$query_charset->execute();

#query preparation
my $query_add_file = $db->prepare("INSERT INTO files (name, size, extension, type, id_host, path) VALUES (?, ?, ?, ?, ?, ?)") or die "\nUnable to prepare file insertion query : $db->errstr";
my $query_add_duplicate = $db->prepare("INSERT INTO duplicates VALUES (?, ?)") or die "\nUnable to prepare add duplicate query : $db->errstr";
my $query_duplicate = $db->prepare("SELECT id, size, path FROM files WHERE name LIKE ?") or die "\nUnable to prepare select duplicate query : $db->errstr";

#indexation
print "Starting indexation...\n";
indexe($indexer, $path);
print "Indexation terminated";

if($number_files > 0 || $number_indexed_files > 0) {
	print "\n$number_files files found";
	print "\n$number_duplicates duplicates found";
	print "\n$number_indexed_files indexed successfully!\n";
}
else {
	print "\nNo file found\n";
}

#close prepared queries and database connection
$query_add_file->finish();
$query_add_duplicate->finish();
$query_duplicate->finish();
$db->disconnect();

$indexer->end();

sub factory {
	my $uri = $_[0];
	if($uri->scheme eq "ftp") {
		return AbstractListing::FTP->new($uri->host, $uri->port, $uri->user, $uri->password);
	}
	if($uri->scheme eq "file") {
		return AbstractListing::HDD->new();
	}
}

sub indexe {
	my $indexer = $_[0];
	my $path = $_[1];
	my @list = $indexer->list($path);
	#local %types;
	foreach my $element (@list) {
		my %file = %{$element};
		if($file{"folder"} == 1) {
			indexe($indexer, $indexer->addFolderToPath($path, $file{"name"}));
		}
		else {
			print "\t".$file{"name"};
			#check if file has a known extension
			my $type = ($types{$file{"extension"}}) ? $types{$file{"extension"}} : "unknown";
			if(grep ($_ eq $file{"extension"}, @filter_extensions) && grep ($_ eq $type, @filter_types)) {
				#search for doubles
				my $duplicate;
				if($check_for_duplicate) {
					#$file{"path"} = q{$path};
					$duplicate = checkDuplicate(\%file);
					if($duplicate == -1) {
						print " > Already in database";
					}
				}
				if($check_for_duplicate == 0 || $check_for_duplicate == 1 && $duplicate >= 0) {
					#add file in database
					push(@all_files, $file{"name"});
					$query_add_file->execute($file{"name"}, $file{"size"}, $file{"extension"}, $type, $host_id, $path) or die "\nUnable to add file in database : $db->errstr";
					print " > Indexed";
					$number_indexed_files++;
				}
				#add a duplicate
				if($check_for_duplicate && $duplicate > 0) {
					$query_add_duplicate->execute($db->{q{mysql_insertid}}, $duplicate);
					print " > Duplicate spotted";
					$number_duplicates++;
				}
			}
			else {
				print " > Not indexed";
			}
			print "\n";
			$number_files++;
		}
	}
	undef @list;
}

sub checkDuplicate {
	my %file = %{$_[0]};
	#search a file with same name in built list
	if(!grep ($_ eq $file{"name"}, @all_files)) {
		return 0;
	}
	#search a file with the same name in database
	$query_duplicate->execute($file{"name"}) or die "\nUnable to check for double in database : $db->errstr";
	if(my @other_file = $query_duplicate->fetchrow_array()) {
		if($other_file[1] == $file{"size"} && $other_file[2] == $file{"path"}) {
			return -1;
		}
		my $min_size = $file{"size"} * (1 - $approximation);
		my $max_size = $file{"size"} * (1 + $approximation);
		if($other_file[1] && $other_file[1] > $min_size && $other_file[1] < $max_size) {
			return $other_file[0];
		}
	}
	return 0;
}
