
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
	'NAME' => 'OOPS',
	'DISTNAME' => 'OOPS',
	'VERSION_FROM' => 'lib/OOPS.pm',
	($] >= 5.005 ?
	    ('ABSTRACT' => 'Store any object in a RDBMS',
	     'AUTHOR'	=> 'David Muir Sharnoff <muir@idiom.com>') : ()),
	'dist'   => {COMPRESS=>'gzip', SUFFIX=>'gz'},
	'PREREQ_PM' => {
		'DBI' => 1.40,
		'Digest::MD5' => 0,
		'Scalar::Util' => 0,
		'Filter::Util::Call' => 0,
	 },
);

package MY;

sub postamble {
    <<"END_OF_POSTAMBLE";

pm_to_blib: README

README: lib/OOPS.pod
\tpod2text lib/OOPS.pod >README

END_OF_POSTAMBLE
}
