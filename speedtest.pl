#!/pro/bin/perl

# speedtest.pl - test network speed using speedtest.net
# (m)'14 [2014-10-10] Copyright H.M.Brand 2014-2014

use 5.12.0;
use warnings;

my $VERSION = "0.05";

sub usage
{
    my $err = shift and select STDERR;
    print <<"EOH";
usage: $0 [ --no-geo | --country=NL ] [ --list | --ping ] [ options ]
       --geo          use Geo location (default true) for closest testserver
    -c --country=IS   use ISO country code for closest test server

    -l --list         list test servers in chosen country
    -p --ping         list test servers in chosen country with latency

    -s --server=nnn   use testserver with id nnn
       --download     test download speed (default true)
       --upload       test upload   speed (default true)
    -q --quick[=20]   do a quick test (only the fastest 20 tests)
    -Q --realquick    do a real quick test (only the fastest 10 tests)
    -T --try[=5]      try all tests on th n fastest servers

    -v --verbose[=1]  set verbosity
    -V --version      show version and exit
    -? --help         show this help

  $0 --list
  $0 --ping --country=BE
  $0
  $0 -s 4358
  $0 -q --no-download
  $0 -Q --no-upload
  
EOH
    exit $err;
    } # usage

use Getopt::Long qw(:config bundling);
my $opt_c = "";
my $opt_v = 1;
my $opt_d = 1;
my $opt_u = 1;
my $opt_g = 1;
my $opt_q = 0;
my $opt_T = 1;
GetOptions (
    "help|h|?"		=> sub { usage (0); },
    "V|version!"	=> sub { say $VERSION; exit 0; },
    "v|verbose:2"	=>    \$opt_v,

    "g|geo!"		=>    \$opt_g,
    "c|cc|country=s"	=>    \$opt_c,

    "l|list!"		=> \my $list,
    "p|ping!"		=> \my $ping,

    "T|try:5"		=>    \$opt_T,
    "s|server=i"	=> \my $server,
    "d|download!"	=>    \$opt_d,
    "u|upload!"		=>    \$opt_u,
    "q|quick|fast:20"	=>    \$opt_q,
    "Q|realquick:10"	=>    \$opt_q,

    "m|mini=s"		=> \my $mini,	# NYI
      "source=s"	=> \my $source,	# NYI
    ) or usage (1);

use LWP::UserAgent;
use XML::Simple;
use HTML::TreeBuilder;
use Time::HiRes qw( gettimeofday tv_interval );
use Math::Trig;
use Data::Peek;

my $ua = LWP::UserAgent->new (
    max_redirect => 2,
    agent        => "Opera/25.00 opera 25",
    parse_head   => 0,
    cookie_jar   => {},
    );

# Speedtest.net defines Mbit/s and kbit/s using 1000 as multiplier,
# https://support.speedtest.net/entries/21057567-What-do-mbps-and-kbps-mean-
my $k = 1000;

my $config = get_config ();
my $client = $config->{"client"}   or die "Config saw no client\n";
my $times  = $config->{"times"}    or die "Config saw no times\n";
my $downld = $config->{"download"} or die "Config saw no download\n";
my $upld   = $config->{"upload"}   or die "Config saw no upload\n";
$opt_v > 3 and DDumper {
    client => $client,
    times  => $times,
    down   => $downld,
    up     => $upld,
    };

if ($opt_g && !$opt_c) {	# Try GeoIP
    $opt_v > 5 and say STDERR "Testing Geo location";
    my $url = "http://www.geoiptool.com";
    my $rsp = $ua->request (HTTP::Request->new (GET => $url));
    if ($rsp->is_success) {
	my $tree = HTML::TreeBuilder->new ();
	if ($tree->parse_content ($rsp->content)) {
	    foreach my $e ($tree->look_down (_tag => "div", class => "data-item")) {
		$opt_v > 2 and say STDERR $e->as_text;
		$e->as_text =~ m{Country code(?:\s*:)?\s*([A-Za-z]+)}i or next;
		$opt_c = uc $1;
		last;
		}
	    }
	}
    }
$opt_c ||= "IS";	# Iceland seems like a nice default :P

$opt_v     and say STDERR "Testing for $client->{ip} : $client->{isp} ($opt_c)";

if ($list) {
    my %list = servers ();
    printf "%5d: %-30.30s %-15.15s %7.2f km\n",
	@{$list{$_}}{qw( id sponsor name dist )} for
	    sort { $list{$a}{dist} <=> $list{$b}{dist} } keys %list;
    exit 0;
    }

if ($ping) {
    printf "%5d: %-30.30s %-15.15s %7.2f km %9.3f ms\n",
	@{$_}{qw( id sponsor name dist ping )} for servers_by_ping ();
    exit 0;
    }

# default action is to run on fastest server
my @hosts = grep { $_->{ping} < 10 } servers_by_ping ();
@hosts > $opt_T and splice @hosts, $opt_T;
foreach my $host (@hosts) {
    $host->{sponsor} =~ s/\s+$//;
    $opt_v and printf STDERR "Using %4d: %6.2f km %6.3f ms %s\n",
	$host->{id}, $host->{dist}, $host->{ping}, $host->{sponsor};
    $opt_v > 3 and DDumper $host;
    (my $base = $host->{url}) =~ s{/[^/]+$}{};

    if ($opt_d) {
	$opt_v and print STDERR "Test download ";
	# http://ookla.extraip.net/speedtest/random350x350.jpg
	my @url = map { ("$base/random${_}x${_}.jpg") x 4 }
	    350, 500, 750, 1000, 1500, 2000, 2500, 3000, 3500, 4000;
	my @mnmx = (999999999.999, 0.000);
	my $size = 0;
	my $time = 0;
	$opt_q and splice @url, $opt_q;
	foreach my $url (@url) {
	    my $req = HTTP::Request->new (GET => $url);
	    my $t0 = [ gettimeofday ];
	    my $rsp = $ua->request ($req);
	    my $elapsed = tv_interval ($t0);
	    unless ($rsp->is_success) {
		warn "$url: ", $rsp->status_line, "\n";
		next;
		}
	    my $sz = length $rsp->content;
	    $size += $sz;
	    $time += $elapsed;
	    my $speed = 8 * $sz / $elapsed / $k / $k;
	    $speed < $mnmx[0] and $mnmx[0] = $speed;
	    $speed > $mnmx[1] and $mnmx[1] = $speed;
	    $opt_v     and print  STDERR ".";
	    $opt_v > 2 and printf STDERR "%12.3f %s\n", $speed, $url;
	    }
	$opt_q and print " " x (40 - $opt_q);
	printf "Download: %8.3f Mbit/s\n", 8 * ($size / $time) / $k / $k;
	$opt_v > 1 and printf "  Received %10.2f kb in %9.3f s. [%8.3f - %8.3f]\n",
	    $size / 1024, $time, @mnmx;
	}

    if ($opt_u) {
	$opt_v and print STDERR "Test upload   ";
	my @data = (0 .. 9, "a" .. "Z", "a" .. "z"); # Random pure ASCII data
	my $data = join "" => map { $data[int rand $#data] } 0 .. 4192;
	$data = "content1=".($data x 1024); # Total length just over 4 Mb
	my @mnmx = (999999999.999, 0.000);
	my $size = 0;
	my $time = 0;
	my $url  = $host->{url}; # .php, .asp, .aspx, .jsp
	# see $upld->{mintestsize} and $upld->{maxchunksize} ?
	my @size = ((250_000) x 10, (500_000) x 10, (1_000_000) x 10, (4_000_000) x 10);
	$opt_q and splice @size, $opt_q;
	foreach my $sz (@size) {
	    my $req = HTTP::Request->new (POST => $url);
	    $req->content (substr $data, 0, $sz);
	    my $t0 = [ gettimeofday ];
	    my $rsp = $ua->request ($req);
	    my $elapsed = tv_interval ($t0);
	    unless ($rsp->is_success) {
		warn "$url: ", $rsp->status_line, "\n";
		next;
		}
	    $size += $sz;
	    $time += $elapsed;
	    my $speed = 8 * $sz / $elapsed / $k / $k;
	    $speed < $mnmx[0] and $mnmx[0] = $speed;
	    $speed > $mnmx[1] and $mnmx[1] = $speed;
	    $opt_v     and print  STDERR ".";
	    $opt_v > 2 and printf STDERR "%12.3f %s (%7d)\n", $speed, $url, $sz;
	    }
	$opt_q and print " " x (40 - $opt_q);
	printf "Upload:   %8.3f Mbit/s\n", 8 * ($size / ($time || 1)) / $k / $k;
	$opt_v > 1 and printf "  Sent     %10.2f kb in %9.3f s. [%8.3f - %8.3f]\n",
	    $size / 1024, $time, @mnmx;
	}
    }

### ############################################################################

sub get_config
{
    my $url = "http://www.speedtest.net/speedtest-config.php";
    my $rsp = $ua->request (HTTP::Request->new (GET => $url));
    $rsp->is_success or die "Cannot get config: ", $rsp->status_line, "\n";
    my $xml = XMLin ( $rsp->content,
        keeproot        => 1,
        noattr          => 0,
        keyattr         => [ ],
        suppressempty   => "",
        );
    $opt_v > 5 and DDumper $xml->{settings};
    return $xml->{settings};
    } # get_config

sub get_servers
{
#   my $url = "http://www.speedtest.net/speedtest-servers.php";
    my $url = "http://www.speedtest.net/speedtest-servers-static.php";
    my $rsp = $ua->request (HTTP::Request->new (GET => $url));
    $rsp->is_success or die "Cannot get config: ", $rsp->status_line, "\n";
    my $xml = XMLin ( $rsp->content,
        keeproot        => 1,
        noattr          => 0,
        keyattr         => [ ],
        suppressempty   => "",
        );
    # 4601 => {
    #   cc      => 'NL',
    #   country => 'Netherlands',
    #   dist    => '38.5028663935342602',	# added later
    #   id      => 4601,
    #   lat     => '52.2167',
    #   lon     => '5.9667',
    #   name    => 'Apeldoorn',
    #   sponsor => 'Solcon Internetdiensten N.V.',
    #   url     => 'http://speedtest.solcon.net/speedtest/upload.php',
    #   url2    => 'http://ooklaspeedtest.solcon.net/speedtest/upload.php'
    #   },

    return map { $_->{id} => $_ } @{$xml->{settings}{servers}{server}};
    } # get_servers

sub distance
{
    my ($lat_c, $lon_c, $lat_s, $lon_s) = @_;
    my $rad = 6371; # km

    # Convert angles from degrees to radians
    my $dlat = deg2rad ($lat_s - $lat_c);
    my $dlon = deg2rad ($lon_s - $lon_c);

    my $x = sin ($dlat / 2) * sin ($dlat / 2) +
	    cos (deg2rad ($lat_c)) * cos (deg2rad ($lat_s)) *
		sin ($dlon / 2) * sin ($dlon / 2);

    return 6371 * 2 * atan2 (sqrt ($x), sqrt (1 - $x)); # km
    } # distance

sub servers
{
    my %list = get_servers ();
    if (my $iid = $config->{"server-config"}{ignoreids}) {
	$opt_v > 3 and warn "Removing servers $iid from server list\n";
	delete @list{split m/\s*,\s*/ => $iid};
	}
    delete @list{grep { $list{$_}{cc} ne $opt_c } keys %list};
    %list or die "No servers in $opt_c found\n";
    for (values %list) {
	$_->{dist} = distance ($client->{lat}, $client->{lon},
	    $_->{lat}, $_->{lon});
	}
    return %list;
    } # servers

sub servers_by_ping
{
    my %list = servers;
    $opt_v > 1 and say STDERR "Finding fastest host ...";
    foreach my $h (values %list) {
	my $t = 0;
	if ($server and $h->{id} != $server) {
	    $h->{ping} = 4000;
	    next;
	    }
	my $req = HTTP::Request->new (GET => "$h->{url}/latency.txt");
	for (0 .. 3) {
	    my $t0 = [ gettimeofday ];
	    my $rsp = $ua->request ($req);
	    my $elapsed = tv_interval ($t0);
	    $t += ($rsp->is_success ? $elapsed : 1000);
	    }
	$h->{ping} = $t;
	}
    return sort { $a->{ping} <=> $b->{ping}
	       || $a->{dist} <=> $b->{dist} } values %list;
    } # servers_by_ping