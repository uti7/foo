#!/usr/bin/perl
#use DBI;
#use Carp qw(carp croak);

# example:
# 	one liner;
#		$ perl -sw -e 'require "test.pm";my $s = new test("./test.db");$s->create("foo", 5, 3);my @v = (1,2,3,5,4);$s->replace(\@v);my $sth=$s->cheap_select(undef);while(my @row =$sth->fetchrow_array()){foreach(@row){print "$_,";}print "\n";}'
#
#		in script;
#    use FindBin qw($Bin);
#    use lib "$Bin";
#    use test;

package test1;

	sub new {
		my $class_name = shift;
		my $path = shift;
		my $self = {
			path => $path,
			foo => undef,
			bararray => undef
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
1;

package test2;
	sub new {
		my $class_name = shift;
		my $hoge = shift;
		my $self = {
			hoge => $hoge,
			hogehoge => undef
		};
		return bless $self, $class_name;
	}
 1;
