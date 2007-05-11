#!/usr/bin/perl -I../lib -I..

BEGIN {unshift(@INC, eval { my $x = $INC[0]; $x =~ s!/OOPS(.*)/blib/lib$!/OOPS$1/t!g ? $x : ()})}
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

BEGIN	{
	if ($dbms =~ /sqlite|mysql/) {
		print "1..0 # Skipped: this test not supported on $dbms\n";
		exit;
	}

	unless (eval { require Test::MultiFork }) {
		print "1..0 # Skipped: this test requires Test::MultiFork\n";
		exit;
	}

	$Test::MultiFork::inactivity = 60; 
	import Test::MultiFork qw(stderr bail_on_bad_plan);
}

# 
# This forces a deadlock and then simulates the
# retry that would normally be handled by 
# transaction()
#

my $itarations = 200;
$itarations /= 10 unless $ENV{OOPSTEST_SLOW};

my $common;

$debug = 0;

FORK_ab:

ab:
my $pn = (procname())[1];
srand($$);

a:
lockcommon;
setcommon({});
unlockcommon;

ab:

# --------------------------------------------------
for my $x (1..$itarations) {
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
a:
	rcon;
	eval {
		rcon;
		$r1->{named_objects}{root}{$pn} = $$;
		$r1->commit;
	};
	die $@ if $@;
	$r1->DESTROY();
b:
	rcon;
	eval {
		rcon;
		$r1->{named_objects}{root}{$pn} = $$;
		$r1->commit;
	};
	die $@ if $@;
	$r1->DESTROY();
ab:
	rcon;
	no warnings;
	print "# <$pn> '$r1->{named_objects}{root}{$pn}' should be '$$' ($@)\n"
		unless $r1->{named_objects}{root}{$pn} && $r1->{named_objects}{root}{$pn} == $$;
	exit
		unless $r1->{named_objects}{root}{$pn} && $r1->{named_objects}{root}{$pn} == $$;
	use warnings;
	test($r1->{named_objects}{root}{$pn} && $r1->{named_objects}{root}{$pn} == $$);
	$r1->DESTROY();
ab:
	for(;;) {
		my $try;
		my $done = 1;
		rcon;
ab:
		eval {
			$common = getcommon;
			for my $i (keys %$common) {
				next if $common->{$i};
				$done = 0;
				$try = 1 if $i eq $pn;
			}

			if ($try) {
				$r1->{named_objects}{root}{d} = "x$$";
				$r1->{named_objects}{root}{$pn} = "x$$";
				$r1->commit;
			}
			$r1->DESTROY();
		};
ab:
		last if $done;
		if ($@) {
			if ($@ =~ /$transfailrx/) {
				# normal failures, try again
			} else {
				print "\nBail out! -- $@\n" if $@ && $@ 
			}
		} elsif ($try) {
			lockcommon();
			$common = getcommon;
			$common->{$pn} = 1;
			setcommon($common);
			unlockcommon();
		} else {
			print "# already done, waiting for peers\n";
		}
	}
	$r1->DESTROY();
ab:
	rcon;
	my $r = $r1->{named_objects}{root};
	test($r->{d}, "a victor: $r->{d}");
	if ($r->{d} eq "x$$") {
		test($r->{$pn} eq "x$$", "confirmation");
	}
	$r1->DESTROY();
}

print "# ---------------------------- done ---------------------------\n" if $debug;
$okay--;
print "1..$okay\n";

exit 0; # ----------------------------------------------------

1;
