#!/home/muir/bin/perl -I../lib -I.. -I.

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

use OOPS qw($transfailrx);
use Carp qw(confess);
use Scalar::Util qw(reftype);
use strict;
use warnings;
use diagnostics;
use OOPS::TestCommon;

BEGIN { $Test::MultiFork::inactivity = 60; }
use Test::MultiFork qw(stderr bail_on_bad_plan);
import Test::MultiFork qw(colorize)
	if -t STDOUT;


$debug = 0;

#
# This tests for transaction isolation levels.
# READ COMMITTED and REPEATEABLE READ both fail
# on this.
#
# With mysql, SERIALIZABLE doesn't tolerate more
# than one OOPS active at the same time so we have
# to be careful to clear out the inactive ones.
#

FORK_ab:

ab:

my ($name,$pn,$number) = procname();

a:
	my $to = 'jane';
b:
	my $to = 'bob';

ab:

for my $x (0..200) {
a:
	print "\n\n\n\n\n\n\n\n\n\n" if $debug;
	resetall; 
	$r1->{named_objects}{accounts} = {
		joe => {
			balance => 20,
		},
		jane => {
			balance => 50,
		},
		bob => {
			balance => 30,
		}
	};
	$r1->commit;
	rcon;
	groupmangle('manygroups');
	$r1->DESTROY;
	undef $r1;
	undef $fe;
ab:
	rcon;
	eval {
		my $joe = $r1->{named_objects}{accounts}{joe};
		$joe->{balance} -= 20;
ab:
		my $ato = $r1->{named_objects}{accounts}{$to};
		$ato->{balance} += 20;
		$r1->commit;
	};
	test(! $@ || $@ =~ /$transfailrx/, $@);
ab:
	$r1->DESTROY;
	undef $r1;
	undef $fe;
b:
	rcon;
	my (@bal) = map($r1->{named_objects}{accounts}{$_}{balance}, qw(joe jane bob));
	test($bal[0]+$bal[1]+$bal[2] == 100, "balances @bal");
	$r1->DESTROY;
	undef $r1;
	undef $fe;
ab:
}

print "# ---------------------------- done ---------------------------\n" if $debug;
$okay--;
print "1..$okay\n";

exit 0; # ----------------------------------------------------

1;
