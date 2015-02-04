### Speedtest (a perl CLI)

The provided perl script is a command-line interface to the
[speedtest.net](http://www.speedtest.net/) infrastructure so that
flash is not required

It was written to feature the functionality that speedtest.net offers
without the overhead of flash or java and the need of a browser.

### Raison-d'être

The tool is there to give you a quick indication of the achievable
throughput of your current network. That can drop dramatically if
you are behind (several) firewalls or badly configured networks (or
network parts like switches, hubs and routers).

It was inspired by the same project written in python:
[speedtest-cli](https://github.com/sivel/speedtest-cli), but I
neither like python, nor did I like the default behjavior of that
script. I also think it does not take the right decisions in choosing
the server based on distance instead of speed. That *does* matter if
one has fiber lines. I prefer speed over distance.

#### Requirements

The script requires perl 5.10.0 or newer. It requires the following
modules to be available (from CPAN or from CORE):

- Data::Dumper         CORE module since perl-5.005
- Getopt::Long         CORE module since perl-5
- HTML::TreeBuilder
- LWP::UserAgent
- Math::Trig           CORE module since perl-5.004
- Time::HiRes          CORE module since perl-5.7.3
- XML::Simple
- Data::Peek           optional but recommended. does fallback
                       to Data::Dumper if not available

The script runs on every system that runs perl. I tested on Linux,
HP-UX, AIX and Windows 7.

Debian wheezy will run with just two additional packages:

 # apt-get install libxml-simple-perl libdata-peek-perl

### Contributing

See CONTRIBUTING.md which states where and how you can contribute

### TODO

 - Make an installer
 - Enable alternative XML parsers

### Disclaimer

Due to language implementation, it may report speeds that are not
consistent with the speeds reported by the web interface or other
speed-test tools.  Likewise for reported latencies, which are not
to be compared to those reported by tools like ping.

Share and enjoy

*H.Merijn Brand (Tux)*
h.m.brand@xs4all.nl
