#!/home/muir/bin/perl -I../lib -I..


BEGIN {
	if ($ENV{HARNESS_ACTIVE} && ! $ENV{OOPSTEST_SLOW}) {
		print "1..0 # Skipped: run this by hand or set \$ENV{OOPSTEST_SLOW}\n";
		exit;
	}

	$OOPS::SelfFilter::defeat = 0
		unless defined $OOPS::SelfFilter::defeat;

	for my $m (qw(Data::Dumper Clone::PP)) {
		unless ( eval " require $m " ) {
			print "1..0 # Skipped: this test requires the $m module\n";
			exit;
		}
		$m->import();
	}
}

use OOPS;
use Carp qw(confess);
use Scalar::Util qw(reftype);
use strict;
use warnings;

use OOPS::TestCommon;

import Clone::PP qw(clone);

print "1..314694\n";
my $debug2 = 1;
my $debug3 = 0;

resetall; # --------------------------------------------------
{
	my $realdebug = $debug;
	my $failures = <<'END';
END
	#
	# flags:
	#
	#	V - try with virtual object and regular object
	#	h - set $key to various keys a hash might use
	#	a - set $key to various index an array might use
	#	v - replace $pval with potential values
	#
	# XXX
	# fails:	a- splice(@{$root->{akey}}, $key, 4)
	#
	my $tests = <<'END';
		Vhv- $root->{$key} = $pval

		- my $zz = 7

		- @{$root->{akey}} = ()

		- pop(@{$root->{akey}})

		- unshift(@{$root->{akey}});

		V- $root = {}

		V- $root = []

		V- $root = 7

		Vh- delete $root->{$key}

		a- splice(@{$root->{akey}}, $key, 4)

		v- push(@{$root->{akey}}, $pval);

		v- unshift(@{$root->{akey}}, $pval);

		v- ${$root->{rkey1}} = $pval;

		v- ${$root->{rkey2}} = $pval;

		v- ${$root->{rkey3}} = $pval;

		v- ${$root->{rkey4}} = $pval;

		Vhv- my $x = $pval; $root->{$key} = \$x

		av- $root->{akey}[$key] = $pval

END
	my %failures;
	for my $failure (split(/\n/, $failures)) {
		$failure =~ s/^\s+//;
		$failure =~ s/\s+$//;
		$failures{$failure} = 1;
		print "# adding '$failure'\n" if $debug2;
	}
	for my $test (split(/^\s*$/m, $tests)) {
		$test =~ s/\s*(\S*)-\s//s;
		my $flag = $1;

		my (@virt) = $flag =~ /V/
			? (qw(
				0 
				virtual
			))
			: (0);
		my (@key) = (0);

		if ($flag =~ /h/) {
			@key = (qw(
				'okey'
				'udkey'
				'akey'
				'hkey'
				'0'
				''
				'skey'
				'newkey'
				'rkey1'
				'rkey2'
				'rkey3'
				'eskey'
				'0key'
				undef
			));
		} elsif ($flag =~ /a/) {
			@key = (3, 0, 1, 2, 4..10);
		} 


		no warnings qw(syntax);
		my (@val) = $flag =~ /v/
			? (qw( 
				{} 
				getref(%$root,'udkey')
				\$root->{akey}[3]
				getref(%$root,'okey')
				getref(%{$root->{hkey}},'skey2')
				$root
				''
				'0'
				'12'
				undef
				'xyz' 
				[] 
				['a','b',7] 
				{x=>1,y=>'z'} 
				$root->{akey}
				$root->{skey}
				$root->{hkey} 
				$root->{rkey} 
				$root->{okey} 
				scalar("abcd"x($ocut/4+1)) 
				\'rval2'
				\[7,8,9]
				\{n=>'m'}
			))
#XXX						\$z
			: ( '1' );
		use warnings;

		for my $val (@val) {
			for my $key (@key) {

				my $sub; 
				my $e = <<END;
					\$sub = sub { 
						my \$z = 'ov09'x($ocut/4+1);
						my \$root = shift; 
						my \$pval = $val;
						my \$key = $key;
						no warnings;
						$test
					}
END

				eval $e;
				die "on $test/$val/$key ... $e ... $@" if $@;

				for my $skips (qw(10 00 01 11)) {
					my $skippre = substr($skips, 0, 1);
					my $skippost = substr($skips, 1, 1);
					for my $groupmangle ('onegroup', '', 'manygroups') {
						for my $vobj (@virt) {

							resetall;

							my $desc = "$flag- $test: key=$key val=$val V$vobj.S$skippre$skippost.G$groupmangle";
							$desc =~ s/\A\s*(.*?)\s*\Z/$1/s;
							$desc =~ s/\n\s*/\\n /g;
							$debug = $failures{$desc}
								? 0
								: $realdebug;
							print "# desc='$desc' debug=$debug\n";

							print "# $desc\n" if $debug;

							my $rv = 'rval';
							my $x = 'ov09'x($ocut/4+1);
							my $mroot = {
								# the length of this array should match the flag =~ /a/ array size of @key (above).
								akey => [ '0', undef, 'a12', 19, [], {}, \'r9', scalar('ov02'x($ocut/4+1)), scalar('ov04'x($ocut/4+1)), [1,2,3] ],
								hkey => { skey2 => 'sval2' },
								skey => 'sval',
								okey => 'over' x ($ocut/4 + 1),
								rkey1 => \$rv,
								rkey2 => \[4,5,6],
								rkey3 => \{z=>'q'},
#								rkey4 => \ (scalar('ov01'x($ocut/4+1))),
#XXX								rkey4 => \$x,
								eskey => '',
								udkey => undef,
								'0key' => '0',
							};

							$r1->{named_objects}{root} = clone($mroot);
							$r1->virtual_object($r1->{named_objects}{root}, $vobj) if $vobj;
							$r1->commit;
							rcon;
							if ($groupmangle) {
								groupmangle($groupmangle);
								rcon;
							}

							print "#PROGRESS: BEFORE $desc\n" if $debug2;

							my $proot = $r1->{named_objects}{root};

							test(docompare($mroot, $proot), $desc) unless $skippre;

							print "mroot before: ".Dumper($mroot)."\n" if $debug3;

							&$sub($mroot);

							print "mroot after: ".Dumper($mroot)."\n" if $debug3;
							print "#PROGRESS: PRE CHANGES: $desc\n" if $debug2;
							print "proot before: ".Dumper($proot)."\n" if $debug3;

							print "# EXECUTING: $desc\n" if $debug;

							&$sub($proot);

							print "#PROGRESS: POST CHANGES: $desc\n" if $debug2;
							print "proot after: ".Dumper($proot)."\n" if $debug3;
							print "#PROGRESS: PRE COMPARE: $desc\n" if $debug2;

							test(docompare($mroot, $proot), $desc) unless $skippost;

							print "#PROGRESS: POST COMPARE, PRE COMMIT: $desc\n" if $debug2;

							$r1->commit;

							print "#PROGRESS: POST COMMIT, PRE COMPARE#2: $desc\n" if $debug2;

							test(docompare($mroot, $proot), $desc) unless $skippost;

							print "#PROGRESS: POST COMPARE#2, PRE RECONNECT: $desc\n" if $debug2;

							undef $proot;
							rcon;
# our $xy = 1;

							my $qroot = $r1->{named_objects}{root};

							print "#PROGRESS: POST RECONNECT, PRE COMPARE #3: $desc\n" if $debug2;

							test(docompare($mroot, $qroot), $desc);

							print "#PROGRESS: POST COMPARE #3, PRE DELETES: $desc\n" if $debug2;

							test(!$vobj == !$r1->virtual_object($qroot), $desc) if $flag =~ /V/;

							nukevar($qroot, $mroot);
							delete $r1->{named_objects}{root};

							print "#PROGRESS: POST DELETES, PRE COMMIT: $desc\n" if $debug2;

							$r1->commit;

							print "#PROGRESS: FINAL COMMIT DONE: $desc\n" if $debug2;

							undef $qroot;
							rcon;

							nodata unless $val =~ /root/;
							notied($desc);

							print "#PROGRESS: DONE WITH TEST: $desc\n" if $debug2;
						}
					}
				}
			}
		}
	}
	$debug = $realdebug;
}

resetall; # --------------------------------------------------
print "# ---------------------------- done ---------------------------\n" if $debug;
$okay--;
print "# tests: $okay\n" if $debug;

exit 0; # ----------------------------------------------------

1;
