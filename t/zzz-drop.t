#!/home/muir/bin/perl -I../lib -I..

use OOPS::TestCommon;

print "1..1\n";

if ($test_dsn =~ m{^DBI:SQLite:dbname=(/tmp/OOPStest.\d+.db)$}) {
	unlink($1);
} else {
	eval {
		OOPS->db_domany(\%OOPS::TestCommon::args, <<END);
			DROP TABLE TP_object;
			DROP TABLE TP_attribute;
			DROP TABLE TP_big;
			DROP TABLE TP_counters;
END
	};
}

print "# $@\n" if $@;
print "ok 1\n";

