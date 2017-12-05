#!/usr/bin/perl
#########
# Usage: perl aaa.pl [inputfile]
#########
use strict;
use warnings;
#use XML::XPath;
use File::Basename qw/basename dirname/;

use utf8;
=pod
use open IN => ":encoding(cp932)";
use open OUT => ":encoding(cp932)";
binmode STDIN, ':encoding(cp932)';
binmode STDOUT, ':encoding(cp932)';
binmode STDERR, ':encoding(cp932)';
=cut

use Data::Dumper;

#use FindBin qw($Bin);
#use lib "$Bin";
use lib "../bar";
use test_yoso qw(test1 test2);

my $t1 = new test_yoso::test1("aaa");
$t1->foo("hey");
print "$t1->{foo}\n";
$t1->{foo} = "say";
print "$t1->{foo}\n";

push @{$t1->{test2array}},  new test_yoso::test2(1)  ;

my $t2 = new test_yoso::test2(2);
push @{$t1->{test2array}}, $t2;

$t2 = new test_yoso::test2(3);
push @{$t1->{test2array}}, $t2;

$t1->{test2array}[0]->{hogehoge} = "h";
$t1->{test2array}[1]->{hogehoge} = "hh";
$t1->{test2array}[2]->{hogehoge} = "hhh";
print Dumper($t1);
print $t1->{test2array}[1]{hogehoge};

exit(0);
