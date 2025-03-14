use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use strict;

my @ALLOWED_ARGS = ('INSTALLDIRS','DESTDIR');

# Parse command line arguments and store them as environment variables
while ($_ = shift) {
	my ($k,$v) = split(/=/, $_, 2);
	if (grep(/^$k$/, @ALLOWED_ARGS)) {
		$ENV{$k} = $v;
	}
}
$ENV{DESTDIR} =~ s/\/$//;

# Default install path
my $DESTDIR = $ENV{DESTDIR} || '';
my $INSTALLDIRS = $ENV{INSTALLDIRS} || 'site';
my %merge_compat = ();

if ($ExtUtils::MakeMaker::VERSION >= 6.46) {
	%merge_compat = (
		'META_MERGE'   => {
			resources  => {
				homepage => 'https://github.com/HexaCluster/oid2bytea',
				repository  => {
					type => 'git',
					git => 'git@github.com:HexaCluster/oid2bytea.git',
					web => 'https://github.com/HexaCluster/oid2bytea',
				},
			},
		}
	);
}

WriteMakefile(
	'DISTNAME'	=> 'oid2bytea',
	'NAME'		=> 'oid2bytea',
	'VERSION'	=> '1.0',
	'dist'  => {
			'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz',
			'ZIP'=>'/usr/bin/zip','ZIPFLAGS'=>'-rl'
		   },
	'AUTHOR'       => 'Gilles Darold (gilles@darold.net)',
	'ABSTRACT'     => 'oid2bytea - PostgreSQL large object to bytea converter',
	'EXE_FILES'    => [ qw(oid2bytea) ],
	#'MAN1PODS'     => { 'doc/oid2bytea.pod' => 'blib/man1/oid2bytea.1p' },
	'DESTDIR'      => $DESTDIR,
	'INSTALLDIRS'  => $INSTALLDIRS,
	'clean'	       => {},
	%merge_compat
);
