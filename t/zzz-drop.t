#!/usr/bin/perl -I../lib -I..

BEGIN {unshift(@INC, eval { my $x = $INC[0]; $x =~ s!/OOPS/blib/lib$!/OOPS/t!g ? $x : ()})}
use OOPS::TestCommon;

print "1..1\n";

db_drop();

print "# $@\n" if $@;
print "ok 1\n";

