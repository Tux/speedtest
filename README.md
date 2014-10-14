The provided script is a command-line interface to the speedtest.net
infrastructure so that flash is not required

It was written to feature the functionality that speedtest.net offers
without the overhead of flash or java and the need of a browser.

The tool is there to give you a quick indication of the achievable
throughput of your current network. That can drop dramatically if
you are behind (several) firewalls or badly configure networks (or
network parts like switches, hubs and routers).

It was inspired by the speedtest-cli project written in python, but
I neither like python, nor did I like the default behjavior of
that script, nor do I think it made the right decisions in choosing
the fastest server or the list of servers to start with.

The script requires perl 5.10.0 or newer. It requires the following
modules to be available (from CPAN or from CORE):

 Data::Dumper         CORE module since perl-5.005
 Getopt::Long         CORE module since perl-5
 HTML::TreeBuilder
 LWP::UserAgent
 Math::Trig           CORE module since perl-5.004
 Time::HiRes          CORE module since perl-5.7.3
 XML::Simple

It will use if installed (for debugging)

 Data::Peek


The script runs on every system that runs perl. I tested on Linux,
HP-UX, AIX and Windows 7.

Due to language implementation, it may report speeds that are not
consistent with the speeds reported by the web interface or other
speed-test tools.

Share and enjoy

H.Merijn Brand (Tux)
h.m.brand@xs4all.nl
