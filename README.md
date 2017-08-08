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
name=scanlan
```

# Indexation script
This indexes local files or files from a FTP server. To index local files, simply provide the path to index as a parameter. For FTPs, use an URI, such as ftp://user:password@server:port.

## Options
* extension: filter only files with specified extension.
* type: filter only files with specified type. List if types is available in table "extension".
* approximation: when detecting duplicates, this parameters indicates the acceptable difference between file size.

## Examples
```
perl index.pl --extension=jpg /home/user
perl index.pl --type=music --extension=ogg --approximation=0.05 /home/user/music
perl index.pl --extension=html --extension=js --extension=php --extension=css /var/www
perl index.pl --type==video ftp://user:password@server:port
```
