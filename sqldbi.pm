#!/usr/bin/perl
use DBI;
use Carp qw(carp croak);

# example:
# 	one liner;
#		$ perl -sw -e 'require "sqldbi.pm";my $s = new sqldbi("./test.db");$s->create("foo", 5, 3);my @v = (1,2,3,5,4);$s->replace(\@v);my $sth=$s->cheap_select(undef);while(my @row =$sth->fetchrow_array()){foreach(@row){print "$_,";}print "\n";}'
#
#		in script;
#    use FindBin qw($Bin);
#    use lib "$Bin";
#    use sqldbi;

#{
	package sqldbi;

	sub new {
		my $class_name = shift;
		my $path = shift;
		my $dbh = DBI->connect("dbi:SQLite:dbname=$path", undef, undef, {PrintError => 1, AutoCommit => 0}) || Carp::croak(DBI::errstr);
		my $self = {
			db_name => $path,
			dbh => $dbh
		};
		return bless $self, $class_name;
	}

	sub current {
		my $self = shift;
		my $table_name = shift;
		if(defined($table_name)){
			$self->{current_table} = $table_name;
		}
		return $self->{current_table};
	}

	sub create {
		my $self = shift;
		my $table_name = shift;
		my $n_cols = shift;
		my $n_index = shift;

		my $sql = "CREATE TABLE IF NOT EXISTS " . $table_name;
		my @columns = ();
		for(1..$n_cols){
			push @columns, "c" . $_;
		}
		$self->{columns_spec} = join(",", @columns);
		my $column_def = $self->{columns_spec};

		if($n_index > 0){
			my @pk_columns = ();
			for(1..$n_index){
				push @pk_columns, "c" . $_;
			}
			$self->{pk_columns_spec} = join(",", @pk_columns);
			$column_def .= ", CONSTRAINT pk_". $table_name . " PRIMARY KEY (" . $self->{pk_columns_spec} . ")";
		}
		$sql .= "(" . $column_def . ");";

		my $rc = $self->{dbh}->do($sql) || Carp::croak(DBI::errstr);
		$self->{current_table} = $table_name;
		return $rc;
	}

	sub drop {
		my $self = shift;
		my $table_name = shift;

		my $sql = "DROP TABLE IF EXISTS ";
		if(defined($table_name)){
			$sql .= $table_name;
		}elsif(defined($self->{current_table})){
			$sql .= $self->{current_table};
			$self->{current_table} = undef;
		}else{
			Carp::croak("ERROR: no table determined.");
		}
		$sql .= ";";

		my $rc = $self->{dbh}->do($sql) || Carp::croak(DBI::errstr);
		return $rc;
	}

	sub replace {
		my $self = shift;
		my $values = shift;
		defined($self->{current_table}) || Carp::croak "ERROR: no table determined.";
		my $sql = "REPLACE INTO " . $self->{current_table};
		my $values_str = "";
		foreach my $v (@$values){
			$values_str .= ($v =~ /^([0-9.]+|null)$/i) ? "$v," : "'$v',";
		}
		$values_str =~ s/,$//;
		$sql .= " VAlUES(" . $values_str . ");";
		my $rc = $self->{dbh}->do($sql) || Carp::croak(DBI::errstr);
		return $rc;
	}

	sub insert_or_ignore {
		my $self = shift;
		my $values = shift;
		defined($self->{current_table}) || Carp::croak "ERROR: no table determined.";
		my $sql = "INSERT OR IGNORE INTO " . $self->{current_table};
		my $values_str = "";
		foreach my $v (@$values){
			$values_str .= ($v =~ /^([0-9.]+|null)$/i) ? "$v," : "'$v',";
		}
		$values_str =~ s/,$//;
		$sql .= " VAlUES(" . $values_str . ");";
		my $rc = $self->{dbh}->do($sql) || Carp::croak(DBI::errstr);
		return $rc;
	}

	sub count {
		my $self = shift;
		defined($self->{current_table}) || Carp::croak "ERROR: no table determined.";
		my $sql = "SELECT COUNT(*) FROM ". $self->{current_table} . ";";

		my $row = $self->{dbh}->selectrow_arrayref($sql) || Carp::croak(DBI::errstr);
		return $row->[0];
	}

	sub cheap_select {
		my $self = shift;
		my $additional_sql = shift;
		defined($self->{current_table}) || Carp::croak "ERROR: no table determined.";
		$additional_sql = defined($additional_sql) ? $additional_sql : ";";
		if(defined($self->{sth})){
			$self->{sth}->finish() || Carp::croak(DBI::errstr);
		}
		my $sql = "SELECT * FROM " . $self->{current_table} . " " . $additional_sql;
		$self->{sth} = $self->{dbh}->prepare($sql) || Carp::croak(DBI::errstr);
		$self->{sth}->execute() || Carp::croak(DBI::errstr);
		return $self->{sth};
	}

	sub export {
		my $self = shift;
		my $path = shift;
		my $additional_sql = shift;
		my $sth = $self->cheap_select($additional_sql);
		if(!defined($,)){ $, = "\t"; }

		open(XH, ">$path") || Carp::croak("ERROR: $path: $!");
		while(my @row = $sth->fetchrow_array()){
			print XH @row;
			print XH "\n";
		}
		close XH;
		$self->finish();
		return $self->{sth};
	}

	sub readtsv { # the word is reserved, what import
		my $self = shift;
		my $path = shift;
		open(XH, "<$path") || Carp::croak("ERROR: $path: $!");
		while(my $l = <XH>){
			$l =~ s/\r?\n//;	# chomp $rec;
			my @rec = split /\t/, $l;
			$self->replace(\@rec);
		}
		close XH;
		return 0;
	}

	#
	# generic
	#
	sub do {
		my $self = shift;
		my $sql = shift;

		my $rc = $self->{dbh}->do($sql) || Carp::croak(DBI::errstr);
		$self->{current_table} = $table_name;
		return $rc;
	}

	sub execute {
		my $self = shift;
		my $sql = shift;
		if(defined($self->{sth})){
			$self->{sth}->finish() || Carp::croak(DBI::errstr);
		}
		$self->{sth} = $self->{dbh}->prepare($sql) || Carp::croak(DBI::errstr);
		$self->{sth}->execute() || Carp::croak(DBI::errstr);
		return $self->{sth};
	}

	sub finish {
		my $self = shift;
		my $rc = $self->{sth}->finish();
		undef($self->{sth});
		return $rc;
	}

	sub commit {
		my $self = shift;
		my $rc = $self->{dbh}->commit;
		return $rc;
	}

	sub dbh {
		my $self = shift;
		return $self->{dbh};
	}

	sub db_name {
		my $self = shift;
		return $self->{db_name};
	}

	sub DESTROY {
		my $self = shift;
		if(defined($self->{sth})){
			$self->{sth}->finish();
		}
		$self->{dbh}->commit;
		$self->{dbh}->disconnect;
	}
#}
1; # must be true evaluted
