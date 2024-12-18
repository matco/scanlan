#!/usr/bin/perl
use strict;

use Path::Tiny;
use Config::Tiny;
use Getopt::Long;
use DBI;
use URI;
use URI::file;

#load local dependencies
use lib path($0)->absolute->sibling("lib")->stringify;

use AbstractListing::HDD;
use AbstractListing::FTP;

#retrieve options
#file filters options (warning, filters are cumulative)
my @filter_extensions;
my @filter_types;
#other options
my $approximation = 0.05;
my $is_uri = 0;

GetOptions(
	"extension=s" => \@filter_extensions,
	"type=s" => \@filter_types,
	"approximation=f" => \$approximation,
	"uri" => \$is_uri
);

#retrieve parameter (which is untouched)
my $parameter = @ARGV[0];

if(!$parameter) {
	print "Path or URI is required\n";
	exit
}

#create URI object
my $uri;
if($is_uri) {
	$uri = URI->new($parameter);
}
else {
	#if parameter is a local path, transform it to an URI to normalize parameter management
	$uri = URI::file->new($parameter, "unix");
}

#create good indexer according to URI
my $indexer;
if($uri->scheme eq "file") {
	$indexer = AbstractListing::HDD->new();
}
elsif($uri->scheme eq "ftp") {
	$indexer = AbstractListing::FTP->new($uri->host, $uri->port, $uri->user, $uri->password);
}
else {
	print "Scheme $uri->scheme is not supported\n";
	exit
}
$indexer->init();

#hard coded options
my $check_for_duplicate = 1;

#indexation path
my $path = $uri->path;

#variable initialization
my $number_files = 0;
my $number_indexed_files = 0;
my $number_duplicates = 0;

#my @all_files;
my $host_id = 1;

#configuration
my $config = Config::Tiny->read("config.ini", "utf8");

#database connection
print "Opening database connection...";
my $db = DBI->connect(
	"DBI:MariaDB:database=$config->{database}->{name};host=$config->{database}->{host};port=$config->{database}->{port}",
	$config->{database}->{user},
	$config->{database}->{password}
) or die "\nUnable to connect with $config->{database}->{host}:$config->{database}->{port}";

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
	print "\n$number_indexed_files files indexed successfully!";
	print "\n$number_duplicates duplicates found\n";
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

sub indexe {
	my $indexer = $_[0];
	my $path = $_[1];
	my @list = $indexer->list($path);

	foreach my $element (@list) {
		my %file = %{$element};
		if($file{"folder"} == 1) {
			indexe($indexer, $indexer->addFolderToPath($path, $file{"name"}));
		}
		else {
			print "\t".$file{"name"};
			#retrieve file type
			my $type = ($types{$file{"extension"}}) ? $types{$file{"extension"}} : "unknown";
			#check if file has a known extension and type
			if((!@filter_extensions || grep ($_ eq $file{"extension"}, @filter_extensions)) && (!@filter_types || grep ($_ eq $type, @filter_types))) {
				#search for duplicates
				my $duplicate;
				if($check_for_duplicate) {
					#$file{"path"} = q{$path};
					$duplicate = check_duplicate(\%file);
					#exact same file is already in database
					if($duplicate == 0) {
						print " > Already in database";
					}
					#add as duplicate in database
					elsif($duplicate > 0) {
						$query_add_duplicate->execute($db->{q{mysql_insertid}}, $duplicate);
						print " > Duplicate spotted";
						$number_duplicates++;
					}
				}
				if($duplicate == -1) {
					#push(@all_files, $file{"name"});
					#add file in database
					$query_add_file->execute($file{"name"}, $file{"size"}, $file{"extension"}, $type, $host_id, $path) or die "\nUnable to add file in database : $db->errstr";
					print " > Indexed";
					$number_indexed_files++;
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

sub check_duplicate {
	my %file = %{$_[0]};
	#search a file with same name in built list
	#if(grep ($_ eq $file{"name"}, @all_files)) {
	#	return 0;
	#}
	#search a file with the same name in database
	$query_duplicate->execute($file{"name"}) or die "\nUnable to check for duplicate in database : $db->errstr";
	if(my @other_file = $query_duplicate->fetchrow_array()) {
		if($other_file[1] == $file{"size"} && $other_file[2] == $file{"path"}) {
			#files are considered the same
			return 0;
		}
		my $min_size = $file{"size"} * (1 - $approximation);
		my $max_size = $file{"size"} * (1 + $approximation);
		if($other_file[1] && $other_file[1] > $min_size && $other_file[1] < $max_size) {
			#files are considered as duplicates
			return $other_file[0];
		}
	}
	return -1;
}
