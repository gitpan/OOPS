#!/usr/bin/perl -I../lib -I..

BEGIN {unshift(@INC, eval { my $x = $INC[0]; $x =~ s!/OOPS(.*)/blib/lib$!/OOPS$1/t!g ? $x : ()})}
BEGIN {
	$OOPS::SelfFilter::defeat = 1
		unless defined $OOPS::SelfFilter::defeat;
}
#BEGIN {
#	if ($ENV{HARNESS_ACTIVE} && ! $ENV{OOPSTEST_SLOW}) {
#		print "1..0 # Skipped: run this by hand or set \$ENV{OOPSTEST_SLOW}\n";
#		exit;
#	}
#}
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

modern_data_compare();

print "1..27\n";

resetall; # --------------------------------------------------
{
	my $tests = <<'END';

		#
		# I don't know why this fails.
		# The really weird thing is that the following test
		# does not fail.  They do almost exactly the
		# same thing.  Since this involves references that 
		# contemplate their own navel, I'm releasing OOPS
		# anyway.
		#
		%$root = (
			hkey => { skey2 => 'sval2' },
		);
		$root->{hkey}{'skey2'} = \$root->{hkey}{skey2};
		$root->{eref91} = $root->{hkey}{'skey2'};
		COMMIT
		${$root->{eref91}} = 7039;
		TODO_COMPARE

		%$root = (
			hkey => { skey2 => 'sval2' },
		);
		my $x;
		$x = \$x;
		$root->{hkey}{'skey2'} = $x;
		$root->{eref91} = $root->{hkey}{'skey2'};
		COMMIT
		${$root->{eref91}} = 7039;
		COMPARE

		#
		# This fails because we don't keep the bless 
		# information with the scalar but rather with the
		# ref.
		#
		$root->{x} = 'foobar';
		COMPARE
		$root->{y} = \$root->{x};
		COMPARE
		wa($root->{y});
		COMPARE
		bless $root->{y}, 'baz';
		COMPARE
		COMMIT
		$root->{y} = 7;
		COMMIT
		$root->{y} = \$root->{x};
		wa($root->{y});
		TODO_COMPARE



END
	my $root = {
		h	=> {
			k	=> 'v',
		},
		a	=> [ 'av' ],
		r	=> \'sr',
	};
	supercross7($tests, { baseroot => $root });
}

print "# ---------------------------- done ---------------------------\n" if $debug;
$okay--;
print "# tests: $okay\n" if $debug;

exit 0; # ----------------------------------------------------

1;
