#!/usr/bin/perl -I../lib -I..

BEGIN {
	no warnings;
	$OOPS::SelfFilter::defeat = 0;
}

$ENV{OOPSTEST_SLOW} = 1; 

require "t/integrety.t";

1;
