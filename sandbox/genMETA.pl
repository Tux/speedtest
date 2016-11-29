#!/pro/bin/perl

use strict;
use warnings;

use Getopt::Long qw(:config bundling nopermute);
my $check = 0;
my $opt_v = 0;
GetOptions (
    "c|check"		=> \$check,
    "v|verbose:1"	=> \$opt_v,
    ) or die "usage: $0 [--check]\n";

use lib "sandbox";
use genMETA;
my $meta = genMETA->new (
    from    => "speedtest",
    verbose => $opt_v,
    );

$meta->from_data (<DATA>);

if ($check) {
    $meta->check_encoding ();
    $meta->check_required ();
    $meta->check_minimum ("5.010000", [ "speedtest" ]);
    $meta->done_testing ();
    }
elsif ($opt_v) {
    $meta->print_yaml ();
    }
else {
    $meta->fix_meta ();
    }

__END__
--- #YAML:1.0
name:                    App-SpeedTest
version:                 VERSION
abstract:                Command line interface to speedtest.net
license:                 perl
author:
    - H.Merijn Brand <h.m.brand@xs4all.nl>
generated_by:            Author
distribution_type:       module
provides:
    App::SpeedTest:
        file:            speedtest
        version:         VERSION
requires:
    perl:                5.010000
    Data::Dumper:        0
    Data::Peek:          0
    Getopt::Long:        0
    HTML::TreeBuilder:   0
    LWP::UserAgent:      0
    Math::Trig:          0
    Socket:              0
    Time::HiRes:         0
    XML::Simple:         0
recommends:
    Data::Peek:          0.46
    Getopt::Long:        2.49
    HTML::TreeBuilder:   5.03
    LWP::UserAgent:      6.15
    Socket:              2.024
    Time::HiRes:         1.9741
    XML::Simple:         2.22
configure_requires:
    ExtUtils::MakeMaker: 0
test_requires:
    Test::More:          0
resources:
    license:             http://dev.perl.org/licenses/
    repository:          https://github.com/Tux/speedtest
    homepage:            https://metacpan.org/pod/App::SpeedTest
    bugtracker:          https://github.com/Tux/speedtest/issues
    IRC:                 irc://irc.perl.org/#csv
meta-spec:
    version:             1.4
    url:                 http://module-build.sourceforge.net/META-spec-v1.4.html
