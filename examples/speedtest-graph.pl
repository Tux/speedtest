#!/pro/bin/perl

use 5.14.2;
use warnings;

our $VERSION = "0.02 - 20190822";
our $CMD = $0 =~ s{.*/}{}r;

sub usage {
    my $err = shift and select STDERR;
    say "usage: $CMD [--graph=speedtest.jpg] [--log=speedtest.csv | speedtest.csv]";
    say "       -l LOG  --log=LOG    specify CSV logfile to scan (speedtest.csv)";
    say "       -g JPG  --graph=JPG  specify filename of produced image (speedtest.jpg)";
    exit $err;
    } # usage

use Time::Local;
use Text::CSV_XS "csv";
use Chart::Strip;
use Getopt::Long qw(:config bundling);
GetOptions (
    "help|?"		=> sub { usage (0); },
    "V|version"		=> sub { say "$CMD [$VERSION]"; exit 0; },

    "l|in|csv|log=s"	=> \(my $log = "speedtest.csv"),
    "g|out|graph|jpg=s"	=> \ my $graph,
    "w|width=i"		=> \ my $gwidth,
    "h|height=i"	=> \ my $gheight,

    "v|verbose:1"	=> \(my $opt_v = 0),
    ) or usage (1);

@ARGV && -f $ARGV[0] and $log = shift;

$graph //= $log =~ s{\.\w+$}{.jpg}r;

my %color = (
    Umin   => "#e00000",
    Uspeed => "#800000",
    Umax   => "#b00000",
    Dmin   => "#00e000",
    Dspeed => "#008000",
    Dmax   => "#00b000",
    );

my $headers = "auto";
open my $fh, "<", $log or die "$log: $!\n";
scalar <$fh> =~ m/^"?[0-9]{4}/ and
    $headers = [qw( stamp server ping tests direction speed min max )];
close $fh;

my %data;
foreach my $e (@{csv (in => $log, headers => $headers)}) {
    my @stamp = ($e->{stamp} =~ m/(\d+)/g);
    my $time  = timelocal (@stamp[5,4,3,2], $stamp[1] - 1, $stamp[0] - 1900);

    push @{$data{$e->{direction}.$_}}, {
	time  => $time,
	value => $e->{$_} + 0.,
	color => $color{$e->{direction}.$_},
	} for qw( min speed max );
    }

$gwidth  ||= 640;
$gheight ||= 192;
my $chart = Chart::Strip->new ( width => $gwidth, height => $gheight );
$chart->add_data ($data{$_}, {
    style => "points", color => $color{$_}, label => $_})
	for qw( Umin Umax Dmin Dmax );
$chart->add_data ($data{$_}, {
    style => "line",   color => $color{$_}, label => $_})
	for qw( Uspeed Dspeed );

open  $fh, ">:raw", $graph;
print $fh $chart->jpeg ();
close $fh;
