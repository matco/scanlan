# Scanlan
Scanlan is a collection of Perl scripts used to scan the files shared by the computers of a local network. The details of every file that has been discovered are stored in a database. Scanlan is able to detect similar files.

In details, Scanlan scans all the computers of a LAN and tries to connect to them using the protocols FTP and SMB. Then, it creates an index of the files that are shared by these computers in an SQL database. It's designed to be run during a LAN party to facilitate the search and the download of shared files.

*Unfortunately, the part required to discover all computers of the network has never been finished. The latest version can only be used to index the files of a local file system or from an FTP host.*

## Setup
First, install required Perl libraries with the following command:
```
sudo apt-get install libpath-tiny-perl libconfig-tiny-perl liburi-perl
```

Then, create the SQL database:
```
mariadb -udb_user -pdb_password < scanlan.sql
```

Finally, create a file named `config.ini` at the root of the project with the credentials to connect to the database:
```
[database]
host=db_host
port=db_port
user=db_user
password=db_password
name=db_name
```

## Usage
*Only the part of the project that scans the files is available.*

The script `index.pl` scans the files from the local file system of from any URI (only FTP is implemented for now). To index local files, simply provide the path to scan as a parameter. For an FTP, specify the URI (for example `ftp://user:password@server:port`).

### Options
* extension: index only files with the specified extension.
* type: index only files with the specified type. The list of types is available in the table `extension`.
* approximation: when detecting duplicates, this parameter indicates the acceptable difference of size between two files to consider them identical.
* uri: specifies that the parameter is a URI.

### Examples
```
perl index.pl --extension=jpg /home/user
perl index.pl --type=music --extension=ogg --approximation=0.05 /home/user/music
perl index.pl --extension=html --extension=js --extension=php --extension=css /var/www
perl index.pl --type==video --uri ftp://user:password@server:port
```
