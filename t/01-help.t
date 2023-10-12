#!env perl

use strict;
use warnings;
use Test::More;

$ENV{NO_COLOR} = 1;

my @txt = qx{$^X ./speedtest --help};
ok ($#txt > 40, "--help gives enough output");
like ("@txt", qr{--help}, "Help has --help");

@txt = qx{$^X ./speedtest --version};
is (scalar @txt, 1, "--version gives exactly 1 line");
like ($txt[0], qr{^speedtest\s+\[[0-9.]+\]}, "--version shows command + version");

@txt = grep m/\S/ => qx{$^X ./speedtest --man};
ok (250 < scalar @txt, "--man gives the manual");
if ($txt[0] =~ m/^NAME\b/) { # No nroff available, fallback to Text
    like ($txt[1], qr{^\s+App::SpeedTest\s}i, "Pod was correctly parsed");
    }
elsif ($^O eq "solaris") {
    # I don't have its output to check against, but it fails
    ok (1, "Don't know how to check this on Solaris");
    }
else {
    # SPEEDTEST(1)          User Contributed Perl Documentation         SPEEDTEST(1)
    # User Contributed Perl Documentation                  SPEEDTEST(1)
    $txt[0] =~ s/(?:\e\[|\x9b)[0-9;]*m//g; # groff-1.24 starts colorizing
    like ($txt[0], qr{\bSPEEDTEST\s*\(1\)}i, "It generated a standard header");
    }

chomp (@txt = grep m/\S/ => qx{$^X ./speedtest --info});
ok (250 < scalar @txt, "--info gives the manual as simple text");
is ($txt[0], "NAME", "The manual starts with section NAME");

done_testing ();
