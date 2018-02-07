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

###
package identifier {
  sub new(){
    my $myname = shift;

    my $path = shift;
    my $ident = shift;
    my $type = shift;
    my $nestlevel = shift;

    Carp::croak("ERROR: no type.") unless(defined($type));

    my $self = {
      ident => $ident,
      type => $type,
      nestlevel => $nestlevel,
      path => $path,
      members => (), 
    };
    return bless $self, $myname;
  }
  sub type(){
    my $self = shift;
    my $type = shift;
    if(defined($type)){
      $self->{type} = $type;
    }
    return $self->{type};
  }
  sub ident(){
    my $self = shift;
    my $ident = shift;
    if(defined($ident)){
      $self->{type} = $ident;
    }
    return $self->{ident};
  }
  sub add_members(){
    my $self = shift;
    my $member_name = shift;
    Carp::croak("ERROR: no  member name.") unless(defined($member_name));
    push @{$self->{members}}, $member_name;
  }
  sub members(){
    my $self = shift;
    return @{$self->{members}};
  }
};
###

###
#
###
my %state = {idle => 0, inpackage => 1, inhash => 2};
our @ids = ();

our $fh;
if(defined($merge_tags)){
  open($fh, ">>$merge_tags") || die "$merge_tags: $!.";
}else{
	open($fh, ">&STDOUT");
}

find( \&process, $root_dir );

close $fh;

#
#
#
sub process()
{
  return if($_ !~ /\.p[lm]$/);
  #print $fh "$File::Find::name\n";

  our $nest_level = 0;
  our @itree = identifier->new($File::Find::name, "main", "p", $nest_level);
  &invoke_per_file($File::Find::dir, $File::Find::name, $_);
}

#
#
#
sub invoke_per_file()
{
  my $dir = shift;
  my $path = shift;
  my $file = shift;

  #use Cwd;

#my $wd = Cwd::getcwd();
#say $wd;

  my @context = ();
  open(IN, "<", $file) || die "$file: $!.";

  while(my $line = <IN>){
    chomp $line;
    &perform_per_line(split /(\s)+|\b/, $line);
  }
  close(IN);
}

#
#
#
sub perform_per_line()
{
  my @line = @_;
    while(1){
      last if($#line < 0 );
      &treat_token(shift(@line));
    }
  }
  return;
}

#
#
#
sub treat_token()
{
  my $token = shift;

  my $i;
  my $last= "none";

  if($token eq '{'){
    push @context, $token);
    shift(@context) if($#context) > 2 );

    $nest_level++;
    if(defined($i)){
      $i->{nest_level} = $nest_level;
    }

  } elsif($token eq '}'){
    push @context, $token);
    shift(@context) if($#context) > 2 );

    $nest_level--;

  } elsif($token eq 'package'){
    push @context, "p");
    shift(@context) if($#context) > 2 );

    $i = identifier->new($path, undef, "p", $nest_level);
    #push @itree, $i;
    $last_key_word ="p";

  } elsif($token =~ /^(our|local|my)$/ ){
    push @context, "v");
    shift(@context) if($#context) > 2 );

    if(defined($i) && !defined($i->{type})){
      $i->{ident} = "v";
    }
  } elsif($token =~ /^[\$%@]$/ ){
    push @context, $token);
    shift(@context) if($#context) > 2 );

  } elsif($token =~ /^\w+$/ ){
    # identifier
    push @context, "i");
    shift(@context) if($#context) > 2 );

    if(defined($i) && !defined($i->{ident})){
      $i->{ident} = $token;
    }
  }
  
}

=cut

exit $?;
