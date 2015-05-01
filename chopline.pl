#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use POSIX;

use utf8;
use open IN => ":encoding(utf8)";
use open OUT => ":encoding(utf8)";
binmode STDIN, ':encoding(utf8)';
binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';

######
#  引数で与えられたFILE全てを入力ファイル全体として
#  LINE行ずつに分割しファイルへ出力
# 
# usage: 
# 		$ perl this.pl [-l LINE] -o OUT_PREFIX [-h HEADER_FILE] [FILE...]
#
#		-l LINE 省略すると1000行ずつになる
#		-o OUT_PREFIX  出力ファイルは OUT_PREFIX.0001～の連番となる
#		-h HEADER_FILE ヘッダ。各出力ファイルの先頭に HEADER_FILE の内容を出力
#		FILE を省略するとstdinから読む
#
use File::Basename qw/basename dirname/;
if($#ARGV < 0){
	die "Usage: perl " . basename $0 . " [-l LINE] -o OUT_PREFIX [-h HEADER_FILE] [FILE...]"
}

#require("../bin/nt2list_common.pl");
#nt2list_common::signature_out(0);
#my $n_file = "";
#my $is_sort_only = 0;
my $header_file = "";
my $outfile = "";
my $line_count = 1000;	# default
GetOptions('line_count=i' => \$line_count, 'header=s' => \$header_file, 'outfile=s' => \$outfile);

my $header_buf = "";
my $header_line_count = 0;

if($header_file ne ""){
	# ヘッダファイルが指定されていれば分割ファイル毎にファイル内容を出力
	open(FH,  "<$header_file") || die "$header_file:$!";
	while(<FH>){
		$header_buf .= $_;
		$header_line_count++;
	}
	$line_count -= $header_line_count;
	close FH;
}
my $test = $ARGV;
if(!$outfile && !$ARGV){
	die "out file not specifiled, use `-o outfile'\r\n";
}
if(!$outfile){
	$outfile = $ARGV;
}

# ファイルをｎ行ずつに分割する
my $fno = 0;
while(<>){
	if(($. % $line_count) == 1 || $line_count == 1){	# 1行ずつなら毎回
		close FH;
		$fno++;
		my $ofile = sprintf("${outfile}.%04d", $fno);
		open(FH, ">$ofile") || die "$ofile:$!";
		# ヘッダ出力
		if($header_buf ne ""){
			print FH $header_buf;
		}
	}
	print FH $_;
}
#close FH;
