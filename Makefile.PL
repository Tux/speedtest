use strict;
use warnings;

require 5.010;

use ExtUtils::MakeMaker;

my %wm = (
    NAME         => "App::SpeedTest",
    DISTNAME     => "App-SpeedTest",
    ABSTRACT     => "Command line interface to speedtest.net",
    AUTHOR       => "H.Merijn Brand <h.m.brand\@xs4all.nl>",
    VERSION_FROM => "speedtest",
    EXE_FILES    => [ "speedtest" ],
    PREREQ_FATAL => 0,
    PREREQ_PM    => {
	"Data::Dumper"		=> 0,
	"Data::Peek"		=> 0,
	"Getopt::Long"		=> 0,
	"HTML::TreeBuilder"	=> 0,
	"LWP::UserAgent"	=> 0,
	"List::Util"		=> 0,
	"Math::Trig"		=> 0,
	"Socket"		=> 0,
	"Time::HiRes"		=> 0,
	"XML::Simple"		=> 0,
	},
    macro        => { TARFLAGS => "--format=ustar -c -v -f", },
    );
$ExtUtils::MakeMaker::VERSION > 6.30 and $wm{LICENSE} = "perl";

my $rv = WriteMakefile (%wm);

package MY;

sub postamble {
    my @pc;
    $] >= 5.010 && -d "xt" && ($ENV{AUTOMATED_TESTING} || 0) != 1 and
	push @pc,
	    'test ::	lib/App/SpeedTest.pm',
	    '	-@env TEST_FILES="xt/*.t" make -e test_dynamic',
	    '';
    join "\n" =>
	'spellcheck:	lib/App/SpeedTest.pm doc',
	'	pod-spell-check --aspell',
	'',
	'checkmeta:	spellcheck',
	'	perl sandbox/genMETA.pl -c',
	'',
	'fixmeta:	lib/App/SpeedTest.pm distmeta',
	'	perl sandbox/genMETA.pl',
	'',
	'lib/App/SpeedTest.pm:	speedtest',
	'	perl sandbox/make-pm',
	'',
	'tgzdist:	checkmeta fixmeta $(DISTVNAME).tar.gz distcheck',
	'	-@mv -f $(DISTVNAME).tar.gz $(DISTVNAME).tgz',
	'	-@cpants_lint.pl $(DISTVNAME).tgz',
	'	-@rm -f Debian_CPANTS.txt',
	'',
	'doc docs:		doc/speedtest.md doc/speedtest.html doc/speedtest.man',
	'	-@rm -f pod2html.tmp',
	'doc/speedtest.md:	speedtest',
	'	pod2markdown  < $? > $@',
	'doc/speedtest.html:	speedtest',
	'	pod2html      < $? 2>&1 | grep -v "^Cannot find" > $@',
	'doc/speedtest.3:	speedtest',
	'	pod2man       < $? > $@',
	'doc/speedtest.man:	doc/speedtest.3',
	'	nroff -mandoc < $? > $@',
	'',
	@pc;
    } # postamble

1;
