#!/usr/bin/perl
#########
# Usage: perl teser.pl
#########
use strict;
use warnings;
use File::Basename qw/basename dirname/;

use utf8;

use Data::Dumper;

#use FindBin qw($Bin);
#use lib "$Bin";

use lib "../bar";
use test_yoso;

my $t1 = new test_yoso::test1("aaa");

########
# property
########
$t1->{foo} = "Hey";     # set immediately
print "$t1->{foo}\n";   # get

########
# method
########
$t1->foo("Say");
print "$t1->{foo}\n";

########
# array of sub structure
########
push @{$t1->{test2array}},  new test_yoso::test2(1)  ;

my $t2 = new test_yoso::test2(2);
push @{$t1->{test2array}}, $t2;

$t2 = new test_yoso::test2(3);
push @{$t1->{test2array}}, $t2;

########
# sub structure member access
########
$t1->{test2array}[0]->{hogehoge} = "h";
$t1->{test2array}[1]->{hogehoge} = "hh";
$t1->{test2array}[2]{hogehoge} = "hhh";

print Dumper($t1);

print $t1->{test2array}[1]{hogehoge};

exit(0);
