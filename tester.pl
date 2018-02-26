#!/usr/bin/perl
#########
# Usage: perl teser.pl
#########
use strict;
use warnings;
use warnings;
use v5.10;
use File::Basename qw/basename dirname/;

use utf8;

use Data::Dumper;

use FindBin qw($Bin);
use lib "$Bin";

use lib "../bar";
use test_yoso;
use test_pkg;

use constant DEBUG => 0;
use constant {
        SEC   => 0,
        MIN   => 1,
        HOUR  => 2,
        MDAY  => 3,
        MON   => 4,
        YEAR  => 5,
        WDAY  => 6,
        YDAY  => 7,
        ISDST => 8,
    };

    use constant WEEKDAYS => qw(
        Sunday Monday Tuesday Wednesday Thursday Friday Saturday
    );

my $t1 = new test_yoso::test1("aaa");

########
# property
########
$t1->{foo} = "Hey";     # set immediately
print "$t1->{foo}\n";   # get

#print ">t1_iii= $test1->iii\n";
$test_yoho::test2::iii = "JJJ";
print "t2_iii= $test_yoho::test2::iii\n";
########
# method
########
$t1->foo("Say");
print "$t1->{foo}\n";

########
# array of sub structure
########
push @{$t1->{bararray}},  new test_yoso::test2(1)  ;

my $t2 = new test_yoso::test2(2);
push @{$t1->{bararray}}, $t2;

$t2 = new test_yoso::test2(3);
push @{$t1->{bararray}}, $t2;

########
# sub structure member access
########
$t1->{bararray}[0]->{hogehoge} = "h";
$t1->{bararray}[1]->{hogehoge} = "hh";
$t1->{bararray}[2]{hogehoge} = "hhh";

print Dumper($t1);

print $t1->{bararray}[1]{hogehoge};
print "\n";
my $c = tvchannel->new();
say $c->{tbs} . "\n";

say $dayofweek::sunday;

print "Today is ", (WEEKDAYS)[ (localtime)[WDAY] ];
exit(0);
