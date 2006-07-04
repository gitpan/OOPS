
package OOPS::Upgrade::To1004;

use OOPS::Setup;

sub upgrade
{
	my ($oops, $oldversion) = @_;

	if ($oldversion ne '1003') {
		require OOPS::Upgrade::To1003;
		OOPS::Upgrade::To1003::upgrade($oops, $oldversion);
	}

	print STDERR "# Schema upgrade to 1004...\n" if $OOPS::debug_upgrade;

	$oops->disconnect() if $oops->{dbh};
	my $dbh = $oops->dbiconnect();
	my $prefix = $oops->{table_prefix};

	if ($oops->{dbms} eq 'pg') {

		unless($dbh->do("DROP TABLE ${prefix}temp;")) {
			$dbh->disconnect();
			$dbh = $oops->dbiconnect();
		}

		my ($oldver) = $dbh->selectrow_array(<<END) or die $dbh->errstr;
			SELECT	alen
			FROM	${prefix}object
			WHERE	id = 1
END
		
		die "oldver=$oldver" unless $oldver eq '1003';

		$dbh->do(<<END) or die $dbh->errstr;
			CREATE TABLE ${prefix}temp AS
			SELECT	* FROM ${prefix}big;
END
		$dbh->do(<<END) or die $dbh->errstr;
			DROP TABLE ${prefix}big;
END

		$dbh->do(<<END) or die $dbh->errstr;
			CREATE TABLE ${prefix}big (
				id		BIGINT NOT NULL, 
				pkey		BYTEA,
				pval		BYTEA,
				PRIMARY KEY (id, pkey));
END
		
		my $count = $dbh->do(<<END) or die $dbh->errstr;
			INSERT	INTO ${prefix}big
			SELECT	id, pkey, DECODE(pval, 'escape')
			FROM	${prefix}temp;
END

		print STDERR "# Upgrading to scheema 1004, $count rows of ${prefix}big converted.\n"
			if $OOPS::debug_upgrade;

		$dbh->do(<<END) or die $dbh->errstr;
			DROP TABLE ${prefix}temp;
END
	}
		
	$dbh->do(<<END) or die $dbh->errstr;
		UPDATE ${prefix}object
		SET alen = 1004
		WHERE id = 1
END

	$dbh->commit() or die $dbh->errstr;
	$dbh->disconnect();

	$oops->{arraylen}{1} = '1004';	# in case it is saved
}

1;

__END__
		my $qread = $dbh->prepare(<<END) or die $dbh->errstr;
			SELECT id, pkey, DECODE(pval, 'escape')
			FROM $oops->{table_prefix}temp
END
		$qread->execute() or die $dbh->errstr;
		my $qwrite = $dbh->prepare(<<END) or die $dbh->errstr;
			INSERT INTO $oops->{table_prefix}big
			VALUES (?, ?, ?)
END
		my $count = 0;
		while ((my $id, $pkey, $pval) = $qread->fetchrow_array()) {
print STDERR "CONVERTED $id, '$pkey'...\n";
			$qwrite->execute($id, $pkey, $pval)
				or die $dbh->errstr;
			$count++;
		}
