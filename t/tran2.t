#!/home/muir/bin/perl -I../lib -I..

BEGIN {
	$OOPS::SelfFilter::defeat = 1
		unless defined $OOPS::SelfFilter::defeat;
}
BEGIN {
	for my $m (qw(Data::Dumper Clone::PP)) {
		unless ( eval " require $m " ) {
			print "1..0 # Skipped: this test requires the $m module\n";
			exit;
		}
		$m->import();
	}
}

import Clone::PP qw(clone);

use OOPS;
use Carp qw(confess);
use Scalar::Util qw(reftype);
use strict;
use warnings;
use diagnostics;
use OOPS::TestCommon;

use Test::MultiFork qw(stderr bail_on_bad_plan);
import Test::MultiFork qw(colorize)
	if -t STDOUT;

my $common;

$debug = 0;

# 
# simple test of transaction()
#

FORK_ab:

ab:
my $pn = (procname())[1];

a:
lockcommon;
setcommon({});
unlockcommon;

ab:

# --------------------------------------------------
for my $x (1..200) {
a:
	print "\n\n\n\n\n\n\n\n\n\n" if $debug;
	resetall; 
	$r1->{named_objects}{root} = {};
	$r1->commit;
ab:
	lockcommon();
	$common = getcommon;
	$common->{$pn} = 0;
	setcommon($common);
	unlockcommon();
ab:
	rcon;
a:
	$r1->{named_objects}{root}{$pn} = $$;
	$r1->commit;
b:
	rcon;
	$r1->{named_objects}{root}{$pn} = $$;
	$r1->commit;
ab:
	transaction(sub {
		rcon;
		$r1->{named_objects}{root}{d} = "x$$";
		$r1->{named_objects}{root}{$pn} = "x$$";
		$r1->commit;
	});
ab:
	my $r = $r1->{named_objects}{root};
	test($r->{d}, "a victor: $r->{d}");
	if ($r->{d} eq "x$$") {
		test($r->{$pn} eq "x$$", "confirmation");
	}
}

print "# ---------------------------- done ---------------------------\n" if $debug;
$okay--;
print "1..$okay\n";

exit 0; # ----------------------------------------------------

1;
