#!/pro/bin/perl

# speedtest.pl - test network speed using speedtest.net
# (m)'14 [2014-12-02] Copyright H.M.Brand 2014-2014

use 5.10.0;
use warnings;

my $VERSION = "0.09";

sub usage
{
    my $err = shift and select STDERR;
    (my $p = $0) =~ s{.*/}{};
    print <<"EOH";
usage: $p [ --no-geo | --country=NL ] [ --list | --ping ] [ options ]
       --geo          use Geo location (default true) for closest testserver
       --all          include *all* servers (default only in own country)
    -c --country=IS   use ISO country code for closest test server
    -1 --one-line     show summary in one line

    -l --list         list test servers in chosen country sorted by distance
    -p --ping         list test servers in chosen country sorted by latency
       --url          show server url in list

    -s --server=nnn   use testserver with id nnn
       --url=sss      use specific server url (do not scan) ext php
       --mini=sss     use specific server url (do not scan) ext from sss
       --download     test download speed (default true)
       --upload       test upload   speed (default true)
    -q --quick[=20]   do a quick test (only the fastest 20 tests)
    -Q --realquick    do a real quick test (only the fastest 10 tests)
    -T --try[=5]      try all tests on th n fastest servers

    -v --verbose[=1]  set verbosity
       --simple       alias for -v0
       --ip           show IP for server
    -V --version      show version and exit
    -? --help         show this help

  $p --list
  $p --ping --country=BE
  $p
  $p -s 4358
  $p --url=http://ookla.extraip.net
  $p -q --no-download
  $p -Q --no-upload
  
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
      "simple!"		=> sub { $opt_v = 0; },

      "all!"		=> \my $opt_a,
    "g|geo!"		=>    \$opt_g,
    "c|cc|country=s"	=>    \$opt_c,
    "1|one-line!"	=> \my $opt_1,

    "l|list!"		=> \my $list,
    "p|ping!"		=> \my $ping,
      "url:s"		=> \my $url,
      "ip!"		=> \my $ip,

    "T|try:5"		=>    \$opt_T,
    "s|server=i"	=> \my $server,
    "d|download!"	=>    \$opt_d,
    "u|upload!"		=>    \$opt_u,
    "q|quick|fast:20"	=>    \$opt_q,
    "Q|realquick:10"	=>    \$opt_q,

    "m|mini=s"		=> \my $mini,
      "source=s"	=> \my $source,	# NYI
    ) or usage (1);

use LWP::UserAgent;
use XML::Simple;
use HTML::TreeBuilder;
use Time::HiRes qw( gettimeofday tv_interval );
use Math::Trig;
use Data::Peek;
use Socket qw( inet_ntoa );

my $ua = LWP::UserAgent->new (
    max_redirect => 2,
    agent        => "Opera/25.00 opera 25",
    parse_head   => 0,
    cookie_jar   => {},
    );

binmode STDOUT, ":encoding(utf-8)";

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

if ($url || $mini) {
    $opt_g   = 0;
    $opt_c   = "";
    $server  = "";
    my $ping    = 0.05;
    my $name    = "";
    my $sponsor = "CLI";
    if ($mini) {
	my $t0  = [ gettimeofday ];
	my $rsp = $ua->request (HTTP::Request->new (GET => $mini));
	$ping   = tv_interval ($t0);
	$rsp->is_success or die $rsp->status_line . "\n";
	my $tree = HTML::TreeBuilder->new ();
	$tree->parse_content ($rsp->content) or die "Cannot parse\n";
	my $ext = "";
	for ($tree->look_down (_tag => "script")) {
	    my $c = ($_->content)[0] or next;
	    ref $c eq "ARRAY" && $c->[0] &&
		$c->[0] =~ m/\b (?: upload_? | config ) Extension
			     \s*: \s* "? ([^"\s]+) /xi or next;
	    $ext = $1;
	    last;
	    }
	$ext or die "No ext found\n";
	($url = $mini) =~ s{/*$}{/speedtest/upload.$ext};
	$sponsor = $_->as_text for $tree->look_down (_tag => "title");
	$name  ||= $_->as_text for $tree->look_down (_tag => "h1");
	$name  ||= "Speedtest mini";
	}
    else {
	$name = "Local";
	$url =~ m{/\w+\.\w+$} or $url =~ s{/?$}{/speedtest/upload.php};
	my $t0  = [ gettimeofday ];
	my $rsp = $ua->request (HTTP::Request->new (GET => $url));
	$ping   = tv_interval ($t0);
	$rsp->is_success or die $rsp->status_line . "\n";
	}
    (my $host = $url) =~ s{^\w+://([^/]+)(?:/.*)?}{$1};
    $url = {
	cc      => "",
	country => "",
	dist    => "0.0",
	host    => $host,
	id      => 0,
	lat     => "0.0000",
	lon     => "0.0000",
	name    => $name,
	ping    => $ping * 1000,
	sponsor => $sponsor,
	url     => $url,
	url2    => $url,
	};
    }

if ($server) {
    $opt_c = "";
    $opt_a = 1;
    }
else {
    if ($opt_c) {
	$opt_c = uc $opt_c;
	}
    elsif ($opt_g) {	# Try GeoIP
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
    }

$opt_v and say STDERR "Testing for $client->{ip} : $client->{isp} ($opt_c)";

if ($list) {
    my %list = servers ();
    my @fld = qw( id sponsor name dist );
    my $fmt = "%5d: %-30.30s %-15.15s %7.2f km\n";
    if (defined $url) {
	push @fld, "url0";
	$fmt .= "       %s\n";
	}
    printf $fmt, @{$list{$_}}{@fld}
	for sort { $list{$a}{dist} <=> $list{$b}{dist} } keys %list;
    exit 0;
    }

if ($ping) {
    my @fld = qw( id sponsor name dist ping );
    my $fmt = "%5d: %-30.30s %-15.15s %7.2f km %7.0f ms\n";
    if (defined $url) {
	push @fld, "url0";
	$fmt .= "       %s\n";
	}
    printf $fmt, @{$_}{@fld} for servers_by_ping ();
    exit 0;
    }

# default action is to run on fastest server
my @srvrs = $url ? ($url) : servers_by_ping ();
my @hosts = grep { $_->{ping} < 1000 } @srvrs;
@hosts > $opt_T and splice @hosts, $opt_T;
foreach my $host (@hosts) {
    $host->{sponsor} =~ s/\s+$//;
    if ($opt_v) {
	my $s = "";
	if ($ip) {
	    (my $h =  $host->{url}) =~ s{^\w+://([^/]+)(?:/.*)?$}{$1};
	    my @ad = gethostbyname ($h);
	    $s = join " " => "", map { inet_ntoa ($_) } @ad[4 .. $#ad];
	    }
	printf STDERR "Using %4d: %6.2f km %7.0f ms%s %s\n",
	    $host->{id}, $host->{dist}, $host->{ping}, $s, $host->{sponsor};
	}
    $opt_v > 3 and DDumper $host;
    (my $base = $host->{url}) =~ s{/[^/]+$}{};

    my $dl = "-";
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
	$dl = sprintf "%8.3f Mbit/s", 8 * ($size / $time) / $k / $k;
	$opt_q &&  $opt_v and print " " x (40 - $opt_q);
	$opt_v || !$opt_1 and print "Download: $dl\n";
	$opt_v > 1 and printf "  Received %10.2f kb in %9.3f s. [%8.3f - %8.3f]\n",
	    $size / 1024, $time, @mnmx;
	}

    my $ul = "-";
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
	my @size = map { $_ * 1000 }
	    ((256) x 10, (512) x 10, (1024) x 10, (4192) x 10);
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
	$ul = sprintf "%8.3f Mbit/s", 8 * ($size / ($time || 1)) / $k / $k;
	$opt_q &&  $opt_v and print " " x (40 - $opt_q);
	$opt_v || !$opt_1 and print "Upload:   $ul\n";
	$opt_v > 1 and printf "  Sent     %10.2f kb in %9.3f s. [%8.3f - %8.3f]\n",
	    $size / 1024, $time, @mnmx;
	}
    $opt_1 and print "DL: $dl, UL: $ul\n";
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
    $opt_a or delete @list{grep { $list{$_}{cc} ne $opt_c } keys %list};
    %list or die "No servers in $opt_c found\n";
    for (values %list) {
	$_->{dist} = distance ($client->{lat}, $client->{lon},
	    $_->{lat}, $_->{lon});
	($_->{url0} = $_->{url}) =~ s{/speedtest/upload.*}{};
	$opt_v > 7 and DDumper $_;
	}
    return %list;
    } # servers

sub servers_by_ping
{
    my %list = servers;
    $opt_v > 1 and say STDERR "Finding fastest host out of @{[scalar keys %list]} hosts for $opt_c ...";
    my $pa = LWP::UserAgent->new (
	max_redirect => 2,
	agent        => "Opera/25.00 opera 25",
	parse_head   => 0,
	cookie_jar   => {},
	timeout      => 15,
	);
    foreach my $h (values %list) {
	my $t = 0;
	if ($server and $h->{id} != $server) {
	    $h->{ping} = 40000;
	    next;
	    }
	$opt_v > 5 and printf STDERR "? %4d %-20.20s %s\n",
	    $h->{id}, $h->{sponsor}, $h->{url};
	my $req = HTTP::Request->new (GET => "$h->{url}/latency.txt");
	for (0 .. 3) {
	    my $t0 = [ gettimeofday ];
	    my $rsp = $pa->request ($req);
	    my $elapsed = tv_interval ($t0);
	    $opt_v > 8 and printf STDERR "%4d %9.2f\n", $_, $elapsed;
	    if ($elapsed >= 15) {
		$t = 40;
		last;
		}
	    $t += ($rsp->is_success ? $elapsed : 1000);
	    }
	$h->{ping} = $t * 1000; # report in ms
	}
    return sort { $a->{ping} <=> $b->{ping}
	       || $a->{dist} <=> $b->{dist} } values %list;
    } # servers_by_ping
