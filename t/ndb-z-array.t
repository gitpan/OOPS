#!/home/muir/bin/perl -I../lib -I..

BEGIN {
	no warnings;
	$OOPS::SelfFilter::defeat = 0;
}

require "t/z-array.t";

1;
