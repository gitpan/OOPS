#!/home/muir/bin/perl -I../lib -I..

BEGIN {
	$OOPS::SelfFilter::defeat = 1
		unless defined $OOPS::SelfFilter::defeat;
}
BEGIN {
	if ($ENV{HARNESS_ACTIVE} && ! $ENV{OOPSTEST_SLOW}) {
		print "1..0 # Skipped: run this by hand or set \$ENV{OOPSTEST_SLOW}\n";
		exit;
	}
}
BEGIN {
	for my $m (qw(Data::Dumper Clone::PP Data::Compare)) {
		unless ( eval " require $m " ) {
			print "1..0 # Skipped: this test requires the $m module\n";
			exit;
		}
		$m->import();
	}
}

import Clone::PP qw(clone);
import Data::Compare;

use OOPS;
use Carp qw(confess);
use Scalar::Util qw(reftype);
use strict;
use warnings;
use diagnostics;

use OOPS::TestCommon;

print "1..1079\n";

# $OOPS::debug_tiedvars = 1; XXX broken

sub wb
{
	$fe->workaround27555(@_);
}
my $circ;
sub myrcon;

resetall; # --------------------------------------------------
{
	my $number = 0;
#					$mroot = {
#						skey => 'sval',
#						rkey => \$x,
#						akey => [ 'hv1' ],
#						hkey => { skey2 => 'sval2' },
#					};
	sub selector {
		return 1; # if $number == 1;
		return 0;
	}
	my $FAIL = <<'END';
		#
		# This fails because we don't keep the bless 
		# information with the scalar but rather with the
		# ref.
		#
		$root->{x} = 'foobar';
		$root->{y} = \$root->{x};
		wb($root->{y});
		bless $y, 'baz';
		---
		$root->{y} = 7;
		---
		$root->{y} = \$root->{x};
		wb($root->{y});


END
	my $tests = <<'END';
		$root->{foobar} = 127;

		O=1
		$root->{foobar} = $root;
		---
		delete $root->{foobar};

		O=1
		push(@{$root->{akey}}, $root);
		---
		delete $root->{akey};

		delete $root->{akey};
		delete $root->{hkey};
		delete $root->{rkey};
		$root->{a11} = \$root->{skey};
		wb($root->{a11});
		$root->{A11} = \$root->{a11};
		wb($root->{A11});
		---
		$root->{skey} = 'blah11';

		my $x;
		$root->{zzzz} = \$x;
		$x = 82;
		---
		$root->{nnnn} = \$root->{zzzz};

		O=1
		$root->{acircular} = [];
		push(@{$root->{acircular}}, $root->{acircular});

END
	
	for my $test (split(/^\s*$/m, $tests)) {
		$number++;
		next unless &selector($number);
		my %conf;
		$test =~ s/\A[\n\s]+//;
		$conf{$1} = [ split(' ', $2) ]
			while $test =~ s/([A-Z])=(.*)\n\s*//;
		my (@tests) = split(/\n\s+---\s*\n/, $test);
		my (@func);
		for my $t (@tests) {
			eval "push(\@func, sub { my (\$root, \$subtest, \$subtest2, \$subtest3) = \@_; $t })";
			die "eval <<$t>>of<$test>: $@" if $@;
		}
		my $pre;
		if ($conf{E}) {
			eval "\$pre = sub { my \$root = shift; @{$conf{E}} }";
			die "eval <<@{$conf{E}}>>of<$test>: $@" if $@;
		}

		my (@virt) = defined $conf{V}
			? @{$conf{V}}
			: (qw(0 virtual));
		my (@commits) = defined $conf{C}
			? (grep {$_ <= (2**@tests)} @{$conf{C}})
			: (0..2**(@tests));
		my (@ss) = defined $conf{S}
			? (grep {$_ <= (2**(@tests -1))} @{$conf{S}})
			: (0..2**(@tests -1));
		my (@subtest) = defined $conf{T}
			? @{$conf{T}}
			: (0);
		my (@subtest2) = defined $conf{U}
			? @{$conf{U}}
			: (0);
		my (@subtest3) = defined $conf{X}
			? @{$conf{X}}
			: (0);
		$circ = defined $conf{O};

		my $mroot;
		for my $vobj (@virt) {
			for my $subtest (@subtest) {
				for my $subtest2 (@subtest2) {
					for my $subtest3 (@subtest3) {
						for my $docommit (@commits) {
							for my $dosamesame (@ss) {
								$fe->destroy;
								resetall;
								my $x = 'rval';
								$mroot = {
									skey => 'sval',
									rkey => \$x,
									akey => [ 'hv1' ],
									hkey => { skey2 => 'sval2' },
								};
								&$pre($mroot) if $pre;

								my $c = clone($mroot);
								%$fe = %$c;
								bless $mroot, ref($fe);
								$fe->virtual_object($fe->{hkey}, $vobj) if $vobj;
								$fe->commit;
								myrcon;

								my $sig = "N=$number.V=$vobj.C=$docommit.S=$dosamesame.T=$subtest.U=$subtest2.X=$subtest3-$test";
								print "# $sig\n" if $debug;

								for my $tn (0..$#func) {
									my $tf = $func[$tn];

									print "# EXECUTING $tests[$tn]\n" if $debug;
									&$tf($mroot,$subtest,$subtest2,$subtest3);
									&$tf($fe,$subtest,$subtest2,$subtest3);

									$fe->commit
										if $docommit & 2**$tn;
									print "# COMPARING\n" 
										if $dosamesame & 2**$tn && $debug;
									test(mydocompare($mroot, $fe), "<$tn>$sig")
										if $dosamesame & 2**$tn;
									myrcon
										if $tn < $#func && $docommit & 2**$tn;
								}
								print "# FINAL COMPARE\n" if $debug;
								test(mydocompare($mroot, $fe), "<END>$sig")
							}
						}
					}
				}
			}
		}

		myrcon;

		%$fe = ();
		$fe->commit;
		myrcon;
	}
}

sub myrcon
{
	if ($circ) {
		nukevar($fe);
		$fe->destroy;
	}
	rcon;
}

sub mydocompare
{
	my ($x, $y) = @_;
	my $r = Compare($x, $y);
	return $r if $r;

	#my $x1 = Dumper($x);
	#my $x2 = Dumper($y);
	#return 1 if $x1 eq $x2;
	##print "x1=$x1\nx2=$x2\n";
	
	#my $y1 = YAML::Dump($x);
	#my $y2 = YAML::Dump($y);
	#return 1 if $y1 eq $y2;
	##print "y1=\n$y1\ny2=\n$y2\n";

	#my $b1 = Data::Dump::dump($x);
	#my $b2 = Data::Dump::dump($y);
	#return 1 if $b1 eq $b2;
	#print "b1=$b1\nb2=$b2\n";

	my $c1 = ref2string($x);
	my $c2 = ref2string($y);
	return 1 if $c1 eq $c2;
	print "c1=$c1\nc2=$c2\n";

	#my $z1 = Data::XDumper::Dump($x);
	#my $z2 = Data::XDumper::Dump($y);
	#print "z1=$z1\nz2=$z2\n"; 

	return 0;
}

print "# ---------------------------- done ---------------------------\n" if $debug;
$okay--;
print "# tests: $okay\n" if $debug;

exit 0; # ----------------------------------------------------

1;
