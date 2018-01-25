#!/usr/bin/perl
#########
# Usage: perl aaa.pl [inputfile]
#########
use strict;
use warnings;
use File::Basename qw/basename dirname/;
use Getopt::Long qw(:config posix_default no_ignore_case gnu_compat);
use File::Find;
use Data::Dumper;
use Carp qw(carp croak);
use 5.10.0;

use utf8;
use open IN => ":encoding(utf8)";
use open OUT => ":encoding(utf8)";
binmode STDIN, ':encoding(utf8)';
binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';

my $this_pl = basename $0;
my $usage = << "EOS";
  Usage: perl $this_pl [-d DIR] [-t TAGS]
         TAGS: output by ctags (default: STDOUT)
         DIR find root *.pl *.pm (default: .)
EOS


my $is_help = 0;
my $root_dir = ".";
my $merge_tags = undef;
GetOptions(
	'help|h'=> \$is_help,
	'root_dir|d=s' => \$root_dir,
	'merge_tags|t=s' => \$merge_tags,
);

die $usage if($is_help);
die "$root_dir: $!\n" if( !-d $root_dir);

package pkg {
  sub new(){
    my $myname = shift;
    my $package_name = shift;
    Carp::croak("ERROR: no package name.") unless(defined($package_name));

    my $self = {
      package_name => $package_name,
      variables => (), 
    };
    return bless $self, $myname;
  }
  sub add_variable(){
    my $self = shift;
    my $variable_name = shift;
    Carp::croak("ERROR: no variable_name.") unless(defined($variable_name));
    push @{$self->{variables}}, $variable_name;
  }
  sub variables(){
    my $self = shift;
    return @{$self->{variables}};
  }
};

our $fh;
if(defined($merge_tags)){
  open($fh, ">>$merge_tags") || die "$merge_tags: $!.";
}else{
	open($fh, ">&STDOUT");
}

find( \&process, $root_dir );

close $fh;

sub process()
{
  return if($_ !~ /\.p[lm]$/);
  #print $fh "$File::Find::name\n";
  &parse_package_variable($File::Find::dir, $File::Find::name, $_);
}

sub parse_package_variable()
{
  my $dir = shift;
  my $path = shift;
  my $file = shift;

use Cwd;

my $wd = Cwd::getcwd();
say $wd;

  open(IN, "<", $file) || die "$file: $!.";

  while(my $line = <IN>){
    chomp $line;
    my @token_array = split /(\s)+|\b/, $line;
    my $token;
    while(1){
      last if($#token_array < 0 );
      $token = shift(@token_array);
      next unless(defined($token) && $token !~ /^\s*$/);
      #print $fh $token . "\n";
      print Dumper($token);
      #print STDERR "left: $#token_array \n";
    }
    print $fh  "\n---------\n";
  }
  close(IN);
  return;
}
=cut

exit $?;
