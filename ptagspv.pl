#!/usr/bin/perl
#########
# Usage: see, below
#########
use strict;
use warnings;
use File::Basename qw/basename dirname/;
my $this_pl = basename $0;

my $usage = << "EOS";
  Usage: perl $this_pl [-d DIR] [ { -a TAGS | -o TAGS } ]
         -d DIR  : a root directory what search for *.pl *.pm (default: .)
         -a TAGS : append to tags file. not specify with -o (default: STDOUT)
         -o TAGS : output to tags file. not specify with -a (default: STDOUT)
EOS

my $header = << "EOS";
!_TAG_FILE_FORMAT	2	/extended format; --format=1 will not append ;" to lines/
!_TAG_FILE_SORTED	0	/0=unsorted, 1=sorted, 2=foldcase/
!_TAG_PROGRAM_AUTHOR	uti7	/none\@none.none/
!_TAG_PROGRAM_NAME	independent ctags for perl	//
!_TAG_PROGRAM_URL	http://ctags.github.com	/ditstribute site/
!_TAG_PROGRAM_VERSION	0.1	//
EOS

# requre: 
#  package nesting is NG that use in curly bracket
#
# limit:
# variable is no output that declared in sub 
#
use Getopt::Long qw(:config posix_default no_ignore_case gnu_compat);
use File::Find;
use Data::Dumper;
use Carp qw(carp croak);
$Carp::Verbose = 1;
use 5.10.0;

use utf8;
use open IN => ":encoding(utf8)";
use open OUT => ":encoding(utf8)";
binmode STDIN, ':encoding(utf8)';
binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';



my $is_help = 0;
my $_is_warn = 0;
my $root_dir = ".";
my $append_tags_path = undef;
my $output_tags_path = undef;
GetOptions(
  'help|h' => \$is_help,
  'root_dir|d=s' => \$root_dir,
  'is_warn|w' => \$_is_warn,
  'append_tags_path|a=s' => \$append_tags_path,
  'output_tags_path|o=s' => \$output_tags_path,
);

die $usage if($is_help);
die "$root_dir: $!\n" if( !-d $root_dir);

use constant CONTEXT_MAX => 4; # flow away context meterial

my $_nest_level = 0;
my $_i = undef;
my @_context = ();
my @_appearance  = ();
my $_is_instring = 0;
my $_is_discard = 0;  # whether discard a line
my $_is_skip = 0;  # whether skip to next semicolon
my $_is_next = 0;  # whether skip to end of line
my $_line = "no data"; # whole data that file line
my $_lno = 0; # file line no whitch for debug
my $_current_main = undef; # current file main indentifier

###
package identifier {
  sub new(){
    my $myname = shift;

    my $path = shift;
    my $ident = shift;
    my $token = shift;
    my $type = shift;
    my $nest_level = shift;
    my $parent = shift;

    Carp::croak("ERROR: no path.") unless(defined($path));
    Carp::croak("ERROR: no ident.") unless(defined($ident));
    Carp::croak("ERROR: no type.") unless(defined($type));
    Carp::croak("ERROR: no token.") unless(defined($token));
    Carp::croak("ERROR: no nestlevel.") unless(defined($nest_level));

    my $self = {
      ident => $ident,
      token => $token,
      line => $_line, # in time, perform_per_line
      line_no => $_lno, # in time, perform_per_line
      type => $type,
      nest_level => $nest_level,
      path => $path,
      parent => $parent,  # it may be undef
      members => [],
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
  sub parent(){
    my $self = shift;
    return $self->{parent};
  }
  sub add_members(){
    my $self = shift;
    my $member = shift;
    Carp::carp("WARN: no member") unless(defined($member));
    if(!defined($member->{parent})){
      $member->{parent} = $self;
    }
    push @{$self->{members}}, $member;
  }
  sub members(){
    my $self = shift;
    if(defined($self->{members})){
      return @{$self->{members}}
    }
    return undef;
  }
  sub output(){
    my $self = shift;
    my $fh = shift;

=pod
    if($self->{type} eq "p" && $self->{ident} eq "main"){
      return; # no output
    }
=cut

    #
    # PRINTING
    #
    printf( $fh "%s\t%s\t%d;\t\"^%s\$\t%s\n",
      $self->{ident},
      $self->{path},
      $self->{line_no},
      $self->{line},
      $self->{type},
    );
    if(defined($self->parent())){
      printf( $fh "%s::%s\t%s\t%d;\t\"^%s\$\t%s\n",
        $self->parent()->{ident}, $self->{ident},
        $self->{path},
        $self->{line_no},
        $self->{line},
        $self->{type},
      );
    }

    map { $_->output($fh) if(defined($_)); } $self->members();
  }
};
### end of package

###
# main execute section
###

@_appearance = ();
our $fh;
my $tmp_path;

if(defined($append_tags_path) && defined($output_tags_path)){
  # both specified. do not it
  die &usage;
}elsif(defined($output_tags_path)){
#  $tmp_path = "$ENV{TMP}/$output_tags_path.$$";
#  open($fh, ">$tmp_path") || die "$tmp_path $!.";
  open($fh, ">$output_tags_path") || die "$tmp_path $!.";
}elsif(defined($append_tags_path)){
  open($fh, ">>$append_tags_path") || die "$append_tags_path: $!.";
}else{
  open($fh, ">&STDOUT");
}
print $fh $header;

find( \&process, $root_dir );

foreach (@_appearance){
  $_->output($fh);
}
close $fh;

#if(defined($output_tags_path)){
#`sort $tmp_path >$output_tags_path` || die $!;
#}

###
# subroutines
###
sub process()
{
  return if($_ !~ /\.p[lm]$/);  # exclude filename
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

  $_lno= 0;
  $_line= "no data";
  $_nest_level = 0;
  push @_context, qw/PACKAGE IDENT/ ;

  # main package, it always registerd 1st
  $_i = identifier->new($File::Find::name, "main", "no_token", "p", $_nest_level);
  push @_appearance, $_i;
  $_current_main = $_i;


  open(IN, "<", $wd ."/" . $file) || die "$File::Find::name: $!.";

  while(my $line = <IN>){
    chomp $line;
    $_lno++;
    if(&is_discard($line)){
      next;
    }

    # tag out 3rd field, its a ex cmd.
    # to use identifer constructor
    $_line = $line;

    $line =~ s/^\s+//; # why do you need it even though you have split it below?
    my @l = split /(\s)+|\b/, $line;
    @l = map { $_ if(defined($_)); } @l;
    @l = grep $_ !~ /^\s*$/, @l;
    my @ll; # more split by each charctor for symbols
    foreach (@l){
      if($_ =~ /^\w+$/){ # a word 
        push @ll, $_; # as is
      }else{  # symbols
        push @ll, split //, $_; # as each char
      }
    }
    &perform_per_line(@ll);
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

    # line ending also comment ending
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

#print "DEBUG: token=" . $token . ", lineno=" . $_lno . "\n";

  # skip durling semicolon
  if($_is_skip){
    if($token eq ";"){
      $_is_skip = 0;
      return;
    }
    if($token ne "{" && $token ne "}"){
      return;
    }
  }

  # begin comment skipping
  if($token eq "#"){
    $_is_next = 1;
    return;
  }

  # ignore
  #if($token =~ /^(self|new)$/){
  #  return;
  #}

  if($token eq ";"){
    # semicolon
    #
    # no bracket package, then move it
    my $i = $#_context;
    if($_context[$i] eq "IDENT"){
      $i--;
      if($_context[$i] eq "PACKAGE"){
        $_i = $_appearance[$#_appearance]; # previous packegea item
      }
    }
    push @_context, "SEMICOLON"; shift(@_context) if($#_context > CONTEXT_MAX );

  }elsif($token eq ":"){
    # package name connector
    #
    push @_context, "CLN"; shift(@_context) if($#_context > CONTEXT_MAX );
    
  }elsif($token eq "{"){
    # open curly bracket
    #
    push @_context, "OPEN_CURLY_BRACKET"; shift(@_context) if($#_context > CONTEXT_MAX );

    $_nest_level++;
    $_i->{nest_level} = $_nest_level;

  } elsif($token eq "}"){
    # close curly bracket
    #
    push @_context, "CLOSE_CURLY_BRACKET"; shift(@_context) if($#_context > CONTEXT_MAX );

    $_nest_level--;
    # FIXME: packae end timing 
    #  close bracket, next package word
    #
    # packege end
    if($_i->type() eq "p" && $_i->nest_level == $_nest_level){
      $_i = $_current_main; # return to main
    }
    # sub end
    elsif($_i->type() eq "s" && $_i->nest_level == $_nest_level){
      if(defined($_i->parent())){
        $_i = $_i->parent(); # up to previous
      }else{
        $_i = $_current_main; # return to main
      }
    }
  }elsif($token eq "&"){
    #
    # call subroutine
    #
    push @_context, "AMP"; shift(@_context) if($#_context > CONTEXT_MAX );
  } elsif($token eq "package"){
    # package
    #
    #
    push @_context, "PACKAGE"; shift(@_context) if($#_context > CONTEXT_MAX );
    # packege end
    if($_i->type() eq "p"){
      $_i = $_current_main; # return to main 
    }


  } elsif($token eq "sub" ){
    # sub routine declaration
    #
    push @_context, "SUB"; shift(@_context) if($#_context > CONTEXT_MAX );

  } elsif($token =~ /^(our|local|my)$/ ){
    # variable declaration
    #
    push @_context, "DECL:$token"; shift(@_context) if($#_context > CONTEXT_MAX );

  } elsif($token =~ /^[\$%@]$/ ){
    # variable prefix
    #
    # scalar symbol(i.e. `$') has mean what reg-exp, its bothering
    my $p;
    if($token eq "\$"){
      $p = "S"; # scalar
    }elsif($token eq "%"){
      $p = "H"; # hash
    }elsif($token eq "@"){
      $p = "H"; # list
    }else{
      $p = "U"; # nani kore
    }
    
    push @_context, "VPREFIX:$p"; shift(@_context) if($#_context > CONTEXT_MAX );

  } elsif($token =~ /^\d+$/ ){
    # numeric chunk
    push @_context, "NUM"; shift(@_context) if($#_context > CONTEXT_MAX );
  } elsif($token =~ /^\w+$/ ){
    # identifier
    # basicaly new timing
    #
    my @whatis = &determin_ident($token);

    push @_context, "IDENT"; shift(@_context) if($#_context > CONTEXT_MAX );

    #
    # REGISTERING
    #
    if($whatis[0] eq "PACKAGE"){
      my $qualified_ident = $token;
      my $q;
      my $i = $#_appearance;  # backward ident element no
      while(my $w = pop @whatis){
        if($w eq "CLN"){
          $q = ":";
        }elsif($w eq "IDENT"){
          $q = $_appearance[$i]->ident(); # previous ident FIXME: MISTAKE
          $i--;
        }elsif($w = "PACKAGE"){
          last;
        }
        $qualified_ident = $q . $qualified_ident if($q);
      }
      $_i = identifier->new($File::Find::name, $qualified_ident, "package", "p", $_nest_level);
      push @_appearance, $_i; $_i = $_appearance[$#_appearance];

    }elsif($whatis[0] eq "SUB"){
      my $n;
      if($_i->type() eq "p"){
        $n = identifier->new($File::Find::name, $token, "sub", "s", $_nest_level );
        $_i->add_members($n);
        $_i = $n;
      }
=pod
      elsif(defined($_i->parent()) && $_i->parent()->type() eq "p"){
        $n = identifier->new($File::Find::name, $token, "sub", "s", $_nest_level, $_i->parent());
        $_i->parent()->add_members($n);
        $_i = $n;
      }
=cut
      else{
        $n = identifier->new($File::Find::name, $token, "sub", "s", $_nest_level);
        $_current_main->add_members($n);
        $_i = $n;
      }

    }elsif($whatis[0] eq "VARIABLE"){
      my $n = identifier->new($File::Find::name, $token, $whatis[1], "v", $_nest_level);
      $_i->add_members($n);
      $_is_skip = 1; # until varivale semicolon
    }elsif($whatis[0] eq "CALL_SUB"){
      my $n = identifier->new($File::Find::name, $token, "call sub", "c", $_nest_level);
      $_i->add_members($n);
    }
  }else{
    my $c = join("\t", @_context);
    print STDERR ("NOTICE: $File::Find::name:$_lno: ignored TOKEN. token=[$token] context=[$c]\n") if($_is_warn);
    push @_context, "OTHER"; shift(@_context) if($#_context > CONTEXT_MAX );
  }
  
}

sub determin_ident()
{
  # list returned
  my $token = shift;
  my $c = join("\t", @_context);
  if($c =~ /PACKAGE(\tIDENT\tCLN\tCLN)*$/){
    my $a = $1;
    $a =~ s/^\t// if(defined($a));
    my @r;
    push @r, "PACKAGE";
    push @r, split("\t", $a) if(defined($a));
    return @r;
  }elsif($c =~ /SUB$/){
    return qw/SUB/;
  }elsif($c =~ /DECL:(our|local|my)\tVPREFIX:.$/){
    return ("VARIABLE", $1);
  }elsif($c =~ /AMP$/){
    return qw/CALL_SUB/;
  }
  # hash key
  # value

  $c =~ s/\t/,/g; # for carp print
  #Carp::carp("NOTICE: $File::Find::name:$_lno: ignored indentifier. token=[$token] context=[$c]\n");
  print STDERR ("NOTICE: $File::Find::name:$_lno: ignored indentifier. token=[$token] context=[$c]\n") if($_is_warn);
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
