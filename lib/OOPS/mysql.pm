
package OOPS::mysql;

@ISA = qw(OOPS);

use strict;
use warnings;

sub initialize
{
	my $oops = shift;

	$oops->{do_forcesave} = 1;

	# SET TRANSACTION ISOLATION LEVEL REPEATABLE READ is the default for InnoDB
	#
	# SERIALIZABLE doesn't seem to work but adding LOCK IN SHARE MODE fixes the
	# problem.  http://bugs.mysql.com/bug.php?id=3707
	#
	my $queries = $oops->{queries};
	for my $q (keys %$queries) {
		$queries->{$q} =~ s/(SELECT.*?)(\z|;)/$1 LOCK IN SHARE MODE $2/gsi;
	}
}

sub tabledefs
{
	return <<END;

	CREATE TABLE TP_object (
		id		BIGINT NOT NULL,
		loadgroup	BIGINT, 
		class		VARCHAR(255) BINARY,
		otype		CHAR(1),
		virtual		CHAR(1),
		reftarg		CHAR(1),
		rfe		CHAR(1),
		alen		INT,
		refs		INT, 
		counter		SMALLINT,
		PRIMARY KEY	(id), 
		INDEX		TP_group_index (loadgroup)) 
				TYPE = InnoDB;

	CREATE TABLE TP_attribute (
		id		BIGINT NOT NULL, 
		pkey		VARCHAR(255) BINARY NOT NULL, 
		pval		VARCHAR(255) BINARY, 
		ptype		CHAR(1),
		PRIMARY KEY	(id, pkey),
		INDEX		TP_value_index (pval(15))) 
				TYPE = InnoDB;

	CREATE TABLE TP_big (
		id		BIGINT NOT NULL, 
		pkey		VARCHAR(255) BINARY NOT NULL, 
		pval		LONGBLOB,
		PRIMARY KEY	(id, pkey))
				TYPE = InnoDB;

	CREATE TABLE TP_counters (
		name		VARCHAR(128) BINARY,
		cval		BIGINT,
		PRIMARY KEY	(name));


END
}

sub initial_query_set
{
	return <<END;
END
}

1;
