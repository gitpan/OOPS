#!/home/muir/bin/perl -I../lib -I..

BEGIN	{
	unless (eval { require Time::HiRes }) {
		print "1..0 # Skipped: this test requires the Time::HiRes module\n";
		exit;
	}
	$OOPS::SelfFilter::defeat = 1;
}

use OOPS;
use Time::HiRes qw(gettimeofday tv_interval);

my $target = 0.05;

sub looptime
{
	my $count = shift;
	my $t0 = [gettimeofday];
	for (my $i = 0; $i < $count; $i++) { };
	return tv_interval ( $t0 );
}

my $tint = 0.2;
my $try = 500;

$try *= 2 
	while looptime($try) < $tint;


print "# loopsize = $try\n";
my $int = 10000;
for my $i (0..30) {
	my $tt = looptime($try);
	print "# looptime=$tt\n";
	$int = $tt if $int > $tt;
}
print "# best = $int\n";

my $cps = int($try/$int);
print "# loops per second= $cps\n";
my $best = int($target * $cps);
print "# ideal value: $best\n";
print "# current value: $OOPS::debug_tdelay\n";

if (abs($best - $OOPS::debug_tdelay) < $best / 5) {
	print "1..1\nok 1 # \$OOPS::debug_tdelay is within 20% of $best.\n";
} else {
	print "1..0 # Skipped: Set \$OOPS::debug_tdelay to $best\n";
}

exit 0;
