#!/usr/bin/perl
#use DBI;
#use Carp qw(carp croak);

# example:
#   one liner;
#   $ perl -sw -e 'require "../bar/test_yoso.pm";my $s = new test1("aaa"); ...
#
#    in script;
#    use FindBin qw($Bin);
#    use lib "$Bin";
#    use test_yoso;

package test_yoso::test1;

  sub new {
    my $class_name = shift;
    my $path = shift;
    my $self = {
      path => $path,
      foo => undef,
      bararray => ()
    };
    return bless $self, $class_name;
  }

  sub foo {
    my $self = shift;
    my $foo = shift;
    if(defined($foo)){
      $self->{foo} = $foo;
    }
    return $self->{foo};
  }


package test_yoso::test2;
  sub new {
    my $hoge = shift;
    my $self = {
      hoge => $hoge,
      hogehoge => undef
    };
    return $self;
  }
  our $iii="jjj";
1;
