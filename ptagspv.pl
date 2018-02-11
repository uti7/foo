#!/usr/bin/perl
#########
# Usage: perl aaa.pl [inputfile]
#########
# requre: 
#  package nesting is NG that use in curly bracket
#
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

my $_nest_level = 0;
my $_i = undef;
my @_context = ();
my @_appearance  = ();
my $_is_instring = 0;
my $_is_discard = 0;  # whether discard a line
my $_is_skip = 0;  # whether skip to next semicolon
my $_is_next = 0;  # whether skip to end of line

use constant CONTEXT_MAX => 3; # flow away context meterial

###
package identifier {
  sub new(){
    my $myname = shift;

    my $path = shift;
    my $ident = shift;
    my $type = shift;
    my $nest_level = shift;

    Carp::croak("ERROR: no path.") unless(defined($path));
    Carp::croak("ERROR: no ident.") unless(defined($ident));
    Carp::croak("ERROR: no type.") unless(defined($type));
    Carp::croak("ERROR: no nestlevel.") unless(defined($nest_level));

    my $self = {
      ident => $ident,
      type => $type,
      nest_level => $nest_level,
      path => $path,
      members => undef,
    };
    return bless $self, $myname;
  }
  sub type(){
    my $self = shift;
    my $type = shift;
    return $self->{type};
  }
  sub ident(){
    my $self = shift;
    return $self->{ident};
  }
  sub nest_level(){
    my $self = shift;
    return $self->{nest_level};
  }
  sub add_members(){
    my $self = shift;
    my $member = shift;
    Carp::carp("WARN no member") unless(defined($member));
    push @{$self->{members}}, $member;
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

  &invoke_per_file($_);
}

#
#
#
sub invoke_per_file()
{
  my $file = shift;

use Cwd;

  my $wd = Cwd::getcwd();
#say $wd;

  @_context = ();
  $_is_instring = 0;

  open(IN, "<", $wd ."/" . $file) || die "$File::Find::name: $!.";

  $_nest_level = 0;
  @_appearance = ();
  push @_context, qw/PACKAGE IDENT/ ;
  $_i = identifier->new($File::Find::name, "main", "p", $_nest_level);
  push @_appearance, $_i;


  while(my $line = <IN>){
    chomp $line;
    if(&is_discard($line)){
      next;
    }
    $line =~ s/^\s+//; # why do you need it even though you have split it below?
    my @l = split /(\s)+|\b/, $line;
    @l = map { $_ if(defined($_)); } @l;
    @l = grep $_ !~ /^\s*$/, @l;
    &perform_per_line(@l);
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
    &treat_per_token(shift(@line));
    if($_is_next){
      $_is_next = 0;
      last;
    }
  }
  return;
}

#
#
#
sub treat_per_token()
{
  my $token = shift;

  if($_is_skip){
    if($token =~/^;$/){
      $_is_skip = 0;
    }
    return;
  }

  if($token =~ /^#$/){
    $_is_next = 1;
    return;
  }

  if($token =~ /^;$/){
    # semicolon
    #
    push @_context, "SEMICOLON"; shift(@_context) if($#_context > CONTEXT_MAX );

    
  }elsif($token =~ /^\{$/){
    # open curly bracket
    #
    push @_context, "OPEN_CURLY_BRACKET"; shift(@_context) if($#_context > CONTEXT_MAX );

    $_nest_level++;
    $_i->{nest_level} = $_nest_level;

  } elsif($token =~ /^\}$/){
    # close curly bracket
    #
    push @_context, "CLOSE_CURLY_BRACKET"; shift(@_context) if($#_context > CONTEXT_MAX );

    # FIXME: packae end timing 
    #  close bracket, next package word
    #
    # packege end
    if($_i->type() eq "p" && $_i->nest_level == $_nest_level){
      $_i = $_appearance[0]; # return to main
    }

    $_nest_level--;

  } elsif($token =~ /^package$/){
    # package
    #
    #
    push @_context, "PACKAGE"; shift(@_context) if($#_context > CONTEXT_MAX );
    # packege end
    if($_i->type() eq "p" && $_i->nest_level == $_nest_level){
      $_i = $_appearance[0]; # return to main 
    }


  } elsif($token =~ /^sub$/ ){
    # sub routine declaration
    #
    push @_context, "SUB"; shift(@_context) if($#_context > CONTEXT_MAX );

  } elsif($token =~ /^(our|local|my)$/ ){
    # variable declaration
    #
    push @_context, "DECL"; shift(@_context) if($#_context > CONTEXT_MAX );

  } elsif($token =~ /^[\$%@]$/ ){
    # variable prefix
    #
    push @_context, "VPREFIX"; shift(@_context) if($#_context > CONTEXT_MAX );

  } elsif($token =~ /^\w+$/ ){
    # identifier
    # basicaly new timing
    push @_context, "IDENT"; shift(@_context) if($#_context > CONTEXT_MAX );

    my $whatis = &determin_ident();


    if($whatis eq "PACKAGE"){
      $_i = identifier->new($File::Find::name, $token, "p", $_nest_level);
      push @_appearance, $_i; $_i = $_appearance[$#_appearance];

    }elsif($whatis eq "SUB"){
      $_i = identifier->new($File::Find::name, $token, "s", $_nest_level);
      push @_appearance, $_i; $_i = $_appearance[$#_appearance];

    }elsif($whatis eq "VARIABLE"){
      $_i = identifier->new($File::Find::name, $token, "v", $_nest_level);
      $_appearance[$#_appearance]->add_members($_i);
      $_is_skip = 1; # until varivale semicolon
    }
  }
  
}

sub determin_ident()
{

  my $c = join("\t", @_context);
  if($c =~ /PACKAGE$/){
    return "PACKAGE";
  }elsif($c =~ /SUB$/){
    return "SUB";
  }elsif($c =~ /DECL\tVPREFIX$/){
    return "VARIABLE";
  }
  # hash key
  # value

  Carp::croak("unknown indentifier");
}

sub is_discard(){
  my $line = shift;

  if($line =~ /^=pod/){
    $_is_discard= 1;
    return 1;
  }
  if($_is_discard && $line =~ /^=cut/){
    $_is_discard = 0;
    return 1;
  }

  return $_is_discard;
}

sub is_instring(){
}


exit $?;
