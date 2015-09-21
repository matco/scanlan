CREATE DATABASE IF NOT EXISTS scanlan DEFAULT CHARACTER SET utf8;
USE scanlan;

CREATE TABLE hosts (
	id TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
	name VARCHAR(255) NOT NULL,
	ip VARCHAR(15) NOT NULL,
	port SMALLINT(5) UNSIGNED NOT NULL,
	PRIMARY KEY (id)
);

CREATE TABLE files (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT,
	name VARCHAR(255) NOT NULL,
	size INT UNSIGNED,
	extension VARCHAR(5),
	type VARCHAR(100) NOT NULL,
	id_host TINYINT UNSIGNED NOT NULL,
	path VARCHAR(255) NOT NULL,
	note DECIMAL(6,5) DEFAULT 0,
	vote INT(5) DEFAULT 0,
	consultation INT(5) DEFAULT 0,
	PRIMARY KEY (id)
) DEFAULT CHARSET=utf8, ENGINE=MyISAM;

ALTER TABLE files ADD FULLTEXT filename (name); 

CREATE TABLE duplicates (
	id_file_1 INT UNSIGNED NOT NULL,
	id_file_2 INT UNSIGNED NOT NULL
);

CREATE TABLE extensions (
	extension VARCHAR(5) NOT NULL,
	type VARCHAR(100) NOT NULL,
	PRIMARY KEY (extension)
);

-- fill extensions table with well knwon extensions
INSERT INTO extensions VALUES ('7z','archive');
INSERT INTO extensions VALUES ('cab','archive');
INSERT INTO extensions VALUES ('rar','archive');
INSERT INTO extensions VALUES ('rpm','archive');
INSERT INTO extensions VALUES ('tar','archive');
INSERT INTO extensions VALUES ('zip','archive');

INSERT INTO extensions VALUES ('doc','document');
INSERT INTO extensions VALUES ('txt','document');
INSERT INTO extensions VALUES ('xml','document');

INSERT INTO extensions VALUES ('exe','executable');
INSERT INTO extensions VALUES ('msi','executable');

INSERT INTO extensions VALUES ('bmp','image');
INSERT INTO extensions VALUES ('gif','image');
INSERT INTO extensions VALUES ('jpeg','image');
INSERT INTO extensions VALUES ('jpg','image');
INSERT INTO extensions VALUES ('png','image');
INSERT INTO extensions VALUES ('tiff','image');

INSERT INTO extensions VALUES ('iso','iso');
INSERT INTO extensions VALUES ('mds','iso');
INSERT INTO extensions VALUES ('nrg','iso');

INSERT INTO extensions VALUES ('mp3','music');
INSERT INTO extensions VALUES ('m4a','music');
INSERT INTO extensions VALUES ('ogg','music');
INSERT INTO extensions VALUES ('wma','music');

INSERT INTO extensions VALUES ('avi','video');
INSERT INTO extensions VALUES ('mpeg','video');
INSERT INTO extensions VALUES ('mpg','video');

INSERT INTO extensions VALUES ('asp','web');
INSERT INTO extensions VALUES ('css','web');
INSERT INTO extensions VALUES ('html','web');
INSERT INTO extensions VALUES ('js','web');
INSERT INTO extensions VALUES ('php','web');
