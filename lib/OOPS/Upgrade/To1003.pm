
package OOPS::Upgrade::To1003;

use OOPS::Setup;

sub upgrade
{
	my ($oops, $oldversion) = @_;

	die unless $oldversion eq '1001';

	print STDERR "# Schema upgrade to 1003...\n" if $OOPS::debug_upgrade;

	if ($oops->{dbms} eq 'mysql') {
		$oops->db_domany($oops->{args}, <<END);
			
			ALTER TABLE TP_attribute 
			MODIFY COLUMN pkey VARCHAR(255) BINARY;

			ALTER TABLE TP_big
			MODIFY COLUMN pkey VARCHAR(255) BINARY;
END
	}
	my (@r) = $oops->db_domany($oops->{args}, <<END);

		UPDATE TP_object
		SET alen = 1003
		WHERE id = 1;

END
	$oops->{arraylen}{1} = '1003';	# in case it is saved
}

1;
