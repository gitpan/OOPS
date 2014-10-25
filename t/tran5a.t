#!/usr/bin/perl -I../lib -I..

BEGIN {unshift(@INC, eval { my $x = $INC[0]; $x =~ s!/OOPS/blib/lib$!/OOPS/t!g ? $x : ()})}
BEGIN {
	$OOPS::SelfFilter::defeat = 1
		unless defined $OOPS::SelfFilter::defeat;
}


use OOPS qw($transfailrx);
use Carp qw(confess);
use Scalar::Util qw(reftype);
use strict;
use warnings;
use diagnostics;

use OOPS::TestCommon;
use Clone::PP qw(clone);

modern_data_compare();
BEGIN {
	if ($dbms =~ /sqlite|mysql/) {
		print "# Mysql can't do this because we're currently running\n";
		print "# all SELECTs with FOR UPDATE on them and that single-\n";
		print "# threads access to the database.\n";
		print "# Sqlite can't do this because it only does database-level\n";
		print "# locking\n";
		print "1..0 # Skipped: this test not supported on $dbms\n";
		exit;
	}

	unless (eval { require Test::MultiFork}) {
		print "1..0 # Skipped: this test requires Test::MultiFork\n";
		exit;
	};
	unless (eval { require Time::HiRes}) {
		print "1..0 # Skipped: this test requires Time::HiRes\n";
		exit;
	};

	import Time::HiRes qw(sleep);

	$Test::MultiFork::inactivity = 60; 
	import Test::MultiFork qw(stderr bail_on_bad_plan);
}


my $looplength = 1000;
$looplength /= 10 unless $ENV{OOPSTEST_SLOW};
if ($ENV{OOPSTEST_DSN} && $ENV{OOPSTEST_DSN} =~ /^dbi:mysql/i) {
	printf STDERR "# mysql is very slow at this test, reducing iterations from %d to %d\n",
		$looplength, $looplength / 20;
	$looplength = int($looplength/20);
}
$OOPS::debug_dbidelay = 0;
$debug = 0;


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
	sleep(rand($OOPS::debug_tdelay)/1000) if $OOPS::debug_tdelay && $OOPS::debug_dbidelay;
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
