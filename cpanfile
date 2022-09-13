requires   "Data::Dumper";
requires   "Data::Peek";
requires   "Getopt::Long";
requires   "HTML::TreeBuilder";
requires   "LWP::UserAgent";
requires   "List::Util";
requires   "Math::Trig";
requires   "Socket";
requires   "Time::HiRes";
requires   "XML::Simple";

recommends "Data::Peek"               => "0.51";
recommends "Getopt::Long"             => "2.52";
recommends "HTML::TreeBuilder"        => "5.07";
recommends "LWP::UserAgent"           => "6.67";
recommends "Socket"                   => "2.036";
recommends "Text::CSV_XS"             => "1.48";
recommends "Time::HiRes"              => "1.9770";
recommends "XML::Simple"              => "2.25";

on "configure" => sub {
    requires   "ExtUtils::MakeMaker";
    };

on "test" => sub {
    requires   "Test::More";

    recommends "Test::More"               => "1.302191";
    };
