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

use OOPS qw($transfailrx);
use Carp qw(confess);
use Scalar::Util qw(reftype);
use strict;
use warnings;
use diagnostics;
use OOPS::TestCommon;

my $looplength = 1000;
$OOPS::debug_dbidelay = 0;
$debug = 0;

BEGIN { $Test::MultiFork::inactivity = 60; }
use Test::MultiFork qw(stderr bail_on_bad_plan);
import Test::MultiFork qw(colorize)
	if -t STDOUT;

sub sum;

FORK_ab:

ab:
my $pn = (procname())[1];
srand($$);

a:
	my $to = 'jane';
b:
	my $to = 'bob';

ab:
for my $x (0..$looplength) {
a:
	print "\n\n\n\n\n\n\n\n\n\n" if $debug;
	resetall; 
	%{$r1->{named_objects}} = (
		joe => {
			coin1 => 25,
			coin2 => 10,
		},
		jane => {
			coin3 => 5,
			coin4 => 10,
		},
		bob => {
			coin5 => 50,
		}
	);
	$r1->commit;
	rcon;
	groupmangle('manygroups');
	rcon;
	my (@bal) = map(values %{$r1->{named_objects}{$_}}, qw(joe jane bob));
	no warnings;
	test(sum(@bal) == 100, "coins @bal");
	use warnings;
	$r1->DESTROY;

ab:
	if ($x > $looplength/2) {
		$OOPS::debug_dbidelay = 1;
	}
	rcon;
	my $x = int(rand($OOPS::debug_tdelay)); if ($OOPS::debug_tdelay && $OOPS::debug_dbidelay) { for (my $i = 0; $i < $x; $i++) {} }
	eval {
		my $no = $r1->{named_objects};
		$no->{$to}{coin1} = $no->{joe}{coin1};
		delete $no->{joe}{coin1};
		$r1->commit;
	};
	test(! $@ || $@ =~ /$transfailrx/, $@);
	$r1->DESTROY;
b:
	rcon;
	my (@bal) = map(values %{$r1->{named_objects}{$_}}, qw(joe jane bob));
	no warnings;
	test(sum(@bal) == 100, "coins @bal");
	use warnings;
	$r1->DESTROY;
ab:
}

print "# ---------------------------- done ---------------------------\n" if $debug;
$okay--;
print "1..$okay\n";

exit 0; # ----------------------------------------------------

sub sum
{
	my $s = 0;
	while (@_) {
		my $x = shift;
		$s += $x if defined $x;
	}
	return $s;
}

1;
