#!/home/muir/bin/perl -I../lib -I..

BEGIN {
	no warnings;
	$OOPS::SelfFilter::defeat = 0;
}

require "t/ref2.t";

1;
