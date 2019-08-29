#!/usr/bin/perl

use Test::More;

eval "use Test::Pod::Links tests => 1";
plan skip_all => "Test::Pod::Links required for testing POD Links" if $@;
Test::Pod::Links->new->all_pod_files_ok;
