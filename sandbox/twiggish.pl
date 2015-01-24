use 5.10.0;
use warnings;
use strict;
use LWP::UserAgent;

## switch to a maintained (more performant?) module
use XML::Twig;

use Data::Peek;
##### force the dump of $config, only for this test
my $opt_v = 6;

my $ua = LWP::UserAgent->new (
    max_redirect => 2,
    agent        => "Opera/25.00 opera 25",
    parse_head   => 0,
    cookie_jar   => {},
    );
###NEW THINGS FROM HERE ON
###
my $client;
my $times;
my $downld;
my $upld;
#new
my $ignore_ids;

my %list; ## a global instead my %list =  get_servers (); at line 385
my $config = {}; ## a global

get_config_and_servers_Twig ();

## SAME TEST BUT INVERTED ASSIGNMENT
$config->{client}   = $client or die "Config saw no client\n";
$config->{times}    = $times  or die "Config saw no times\n";
$config->{download} = $downld or die "Config saw no download\n";
$config->{upload}   = $upld   or die "Config saw no upload\n";

$config->{"server-config"}{"ignoreids"} = $ignore_ids
    or die "Config saw no ignore ids\n";

$opt_v > 5 and DDumper $config;

### ############################################################################

sub get_config_and_servers_Twig
{
    my $url = "http://www.speedtest.net/speedtest-config.php";
    my $rsp = $ua->request (HTTP::Request->new (GET => $url));
    $rsp->is_success or die "Cannot get config: ", $rsp->status_line, "\n";

    ##
    my $twig_config = XML::Twig->new (twig_handlers => {
	"settings/client" => sub {
	    map { $$client{$_} = $_[1]->att ($_) }
		qw{ ip isp ispdlavg isprating ispulavg lat loggedin lon rating };
	    },
	# times seems not used by your program!!
	"settings/times" => sub {
	    map { $$times{$_} = $_[1]->att ($_) }
		qw{ dl1 dl2 dl3 ul1 ul2 ul3 };
	    },
	"settings/download" => sub {
	    map { $$downld{$_} = $_[1]->att ($_) }
		qw{ initialtest mintestsize testlength threadsperurl };
	    },
	"settings/upload" => sub {
	    map { $$upld{$_} = $_[1]->att ($_) }
		qw{ initialtest maxchunkcount maxchunksize mintestsize
		    ratio testlength threads threadsperurl };
	    },
	#
	"settings/server-config" => sub {
	    $ignore_ids = $_[1]->att ("ignoreids") },
	    },
	);

    $twig_config->parse ($rsp->content);

    # now get_servers

    my $url_servers = "http://www.speedtest.net/speedtest-servers-static.php";
    my $rsp_servers = $ua->request (HTTP::Request->new (GET => $url_servers));
    # ATTENTION the die was die "Cannot get config: " AND NOT get servers..
    $rsp_servers->is_success or
	die "Cannot get servers ", $rsp_servers->status_line, "\n";
    my $twig_servers = XML::Twig->new (twig_handlers => {
	"settings/servers/server" => sub {
	    $list{$_[1]->att ("id")} = {
		map { $_ => $_[1]->att ($_) }
		    qw{ cc country lat lon name sponsor url url2 }};
	    },
	});
    $twig_servers->parse ($rsp_servers->content);

    # HERE IS TOO SOON.....$opt_v > 5 and DDumper $config;##was $xml->{settings}
    #return $xml->{settings};
    } # get_config_and_servers_Twig
