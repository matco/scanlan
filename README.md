# Setup

Scripts are written in Perl. Some additional Perl libraries are required. They can be installed using following commands:
```
apt-get install libpath-tiny-perl
apt-get install libconfig-tiny-perl
apt-get install liburi-perl
```

An SQL database is required as well. Create it using file "scanlan.sql".
```
mysql -udb_user -pdb_password < scanlan.sql
```

## Configuration

Create a file named config.ini in same path as the others scripts with following content:
```
[database]
host=db_host
port=db_port
user=db_user
password=db_password
name=db_name
```

# Indexation script
This indexes files from local file system of from any URI (only FTP is implemented for now). To index local files, simply provide the path to index as a parameter. For URI, use for example "ftp://user:password@server:port".

## Options
* extension: filter only files with specified extension.
* type: filter only files with specified type. List if types is available in table "extension".
* approximation: when detecting duplicates, this parameters indicates the acceptable difference between file size.
* uri: specify that the parameter is an URI.

## Examples
```
perl index.pl --extension=jpg /home/user
perl index.pl --type=music --extension=ogg --approximation=0.05 /home/user/music
perl index.pl --extension=html --extension=js --extension=php --extension=css /var/www
perl index.pl --type==video --uri ftp://user:password@server:port
```
