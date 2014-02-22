#!/usr/bin/perl
#########
# Usage: perl aaa.pl [inputfile]
#########
use strict;
use warnings;
#use XML::XPath;
use File::Basename qw/basename dirname/;

use utf8;
use open IN => ":encoding(cp932)";
use open OUT => ":encoding(cp932)";
binmode STDIN, ':encoding(cp932)';
binmode STDOUT, ':encoding(cp932)';
binmode STDERR, ':encoding(cp932)';

#my $xp = XML::XPath->new( filename => 'a.xml' );

#print basename "$0" . "\n";

if($#ARGV < 0){
	open(IN, "<&STDIN");
}else{
	open(IN, $ARGV[0]) || die "$ARGV[0]: ${!}.";
}
#my %c = {'foo'=>'bar'};
while(my $s = <IN>){
=pod
	print $s;
  if ($s =~ /(表|ы)/){
    print "○:$s";
  }else{
    print "×:$s";
  }
=cut

}
close(IN);
# changed for test
exit(0);
