#!/pro/bin/perl

use 5.14.2;
use warnings;

use Time::Local;
use Text::CSV_XS "csv";
use Chart::Strip;

my $log = shift // "speedtest.csv";

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

my $chart = Chart::Strip->new ();
$chart->add_data ($data{$_}, {
    style => "points", color => $color{$_}, label => $_})
	for qw( Umin Umax Dmin Dmax );
$chart->add_data ($data{$_}, {
    style => "line",   color => $color{$_}, label => $_})
	for qw( Uspeed Dspeed );

open  $fh, ">", "speedtest-graph.jpg";
print $fh $chart->jpeg ();
close $fh;
