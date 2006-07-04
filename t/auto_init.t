#!/usr/bin/perl -I../lib -I.. 

BEGIN {
	$OOPS::SelfFilter::defeat = 1
		unless defined $OOPS::SelfFilter::defeat;
}
BEGIN {
	#if ($ENV{HARNESS_ACTIVE} && ! $ENV{OOPSTEST_SLOW}) {
	#	print "1..0 # Skipped: run this by hand or set \$ENV{OOPSTEST_SLOW}\n";
	#	exit;
	#}
}

print "1..4\n";

delete $ENV{OOPS_INIT};

use OOPS::TestCommon;  # creates database

nocon;
db_drop();

my %args2 = %args;
delete $args2{no_front_end};

eval { local $SIG{'__DIE__'}; $fe = OOPS->new(%args2) };

test($@ =~ /DBMS not initialized/, $@);
undef $fe;

eval { db_drop() };

eval {
	$fe = OOPS->new(%args2, auto_initialize => 1);

	$fe->{xyz} = { abc => 123 };

	$fe->commit;

	undef $fe;
};
test(! $@, $@);

eval {
	$fe = OOPS->new(%args2, auto_initialize => 1);

	test($fe->{xyz}{abc} == 123);

	undef $fe;
};
test(! $@, $@);

1;
