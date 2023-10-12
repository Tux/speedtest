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

recommends "Data::Dumper"             => "2.154";
recommends "Data::Peek"               => "0.52";
recommends "Getopt::Long"             => "2.54";
recommends "HTML::TreeBuilder"        => "5.07";
recommends "LWP::UserAgent"           => "6.72";
recommends "Socket"                   => "2.037";
recommends "Text::CSV_XS"             => "1.52";
recommends "Time::HiRes"              => "1.9775";
recommends "XML::Simple"              => "2.25";

suggests   "Data::Dumper"             => "2.188";

on "configure" => sub {
    requires   "ExtUtils::MakeMaker";

    recommends "ExtUtils::MakeMaker"      => "7.22";

    suggests   "ExtUtils::MakeMaker"      => "7.70";
    };

on "test" => sub {
    requires   "Test::More";

    recommends "Test::More"               => "1.302195";
    };
