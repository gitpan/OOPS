#!/home/muir/bin/perl -I../lib -I..

BEGIN {
	no warnings;
	$OOPS::SelfFilter::defeat = 1;
}
BEGIN {
	if ($ENV{HARNESS_ACTIVE} && ! $ENV{OOPSTEST_SLOW}) {
		print "1..0 # Skipped: run this by hand or set \$ENV{OOPSTEST_SLOW}\n";
		exit;
	}
}

require "t/slowtest.t";

1;
