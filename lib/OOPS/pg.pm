
package OOPS::pg;

@ISA = qw(OOPS);

use strict;
use warnings;

sub initialize
{
	my $rectangle = shift;
	my $dbh = $rectangle->{dbh};
	#my $tmode = $dbh->prepare('SET TRANSACTION ISOLATION LEVEL READ COMMITTED') || die;
	my $tmode = $dbh->prepare('SET TRANSACTION ISOLATION LEVEL SERIALIZABLE') || die;
	$tmode->execute() || die;

	my $tmode2 = $rectangle->{counterdbh}->prepare('SET TRANSACTION ISOLATION LEVEL READ COMMITTED') || die;
	$tmode2->execute() || die $tmode2->errstr;
}

sub tabledefs
{
	my $x = <<'END';

	CREATE TABLE TP_object (
		id		BIGINT,
		loadgroup	BIGINT, 
		class 		VARCHAR(255), 		# ref($object)
		otype		CHAR(1),		# 'S'calar/ref, 'A'rray, 'H'ash
		virtual		CHAR(1),		# load virutal ('V' or '0')
		reftarg		CHAR(1),		# reference target ('T' or '0')
		rfe		CHAR(1),		# reserved for future expansion
		alen		INT,			# array length
		refs		INT, 			# references
		counter		SMALLINT,
		PRIMARY KEY (id));

	CREATE INDEX TP_group_index ON TP_object (loadgroup);

	CREATE TABLE TP_attribute (
		id		BIGINT NOT NULL, 
		pkey		VARCHAR(128) NOT NULL, 
		pval		VARCHAR(255), 
		ptype		VARCHAR(1),		# type '0'-normal or 'R'eference 'B'ig
		PRIMARY KEY (id, pkey));

	CREATE INDEX TP_value_index ON TP_attribute (pval);

	CREATE TABLE TP_big (
		id		BIGINT NOT NULL, 
		pkey		VARCHAR(128) NOT NULL, 
		pval		TEXT,
		PRIMARY KEY (id, pkey));

	CREATE TABLE TP_counters (
		name		VARCHAR(128),
		cval		BIGINT,
		PRIMARY KEY	(name));

END
	$x =~ s/#.*//mg;
	return $x;
}

sub initial_query_set
{
	return <<END;
END
}

1;

__END__
		saveobjectQ
			INSERT INTO object (object, loadgroup, flags, class, refs, counter)
			VALUES (DEFAULT, ?, ?, ?, ?, 1)
