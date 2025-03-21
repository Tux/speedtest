#!/pro/bin/perl

use strict;
use warnings;

use Getopt::Long qw(:config bundling nopermute);
GetOptions (
    "c|check"		=> \ my $check,
    "u|update!"		=> \ my $update,
    "v|verbose:1"	=> \(my $opt_v = 0),
    ) or die "usage: $0 [--check]\n";

use lib "sandbox";
use genMETA;
my $meta = genMETA->new (
    from    => "speedtest",
    verbose => $opt_v,
    );

$meta->from_data (<DATA>);
$meta->security_md ($update);
$meta->gen_cpanfile ();

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
    - H.Merijn Brand <hmbrand@cpan.org>
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
    List::Util:          0
    Math::Trig:          0
    Socket:              0
    Time::HiRes:         0
    XML::Simple:         0
recommends:
    Data::Dumper:        2.154
    Data::Peek:          0.53
    Getopt::Long:        2.58
    HTML::TreeBuilder:   5.07
    LWP::UserAgent:      6.78
    Socket:              2.038
    Time::HiRes:         1.9777
    XML::Simple:         2.25
    Text::CSV_XS:        1.60
suggests:
    Data::Dumper:        2.189
configure_requires:
    ExtUtils::MakeMaker: 0
configure_recommends:
    ExtUtils::MakeMaker: 7.22
configure_suggests:
    ExtUtils::MakeMaker: 7.72
test_requires:
    Test::More:          0
test_recommends:
    Test::More:          1.302209
resources:
    license:             http://dev.perl.org/licenses/
    homepage:            https://metacpan.org/pod/App::SpeedTest
    repository:          https://github.com/Tux/speedtest
    bugtracker:          https://github.com/Tux/speedtest/issues
    IRC:                 irc://irc.perl.org/#csv
meta-spec:
    version:             1.4
    url:                 http://module-build.sourceforge.net/META-spec-v1.4.html
