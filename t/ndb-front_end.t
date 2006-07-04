#!/usr/bin/perl -I../lib -I..

BEGIN {
	no warnings;
	$OOPS::SelfFilter::defeat = 0;
}

require "t/front_end.t";

1;
