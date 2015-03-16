package lib::Database;

use strict;
use DBI;
use Carp;

sub new {
	my $class = shift;
	my ($dbfile,$user,$passwd) = @_;

	Carp::croak("db file not defined") unless ($dbfile);

	my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile");
	Carp::croak("can't connect to database $DBI::errstr") unless ($dbh);

	my $self = {};
	$self->{dbh} = $dbh;
	return bless $self,$class;
}

sub select {
	my $self = shift;
	my $sql = shift;

	my $dbh = $self->{dbh};
	my $sth = $dbh->prepare($sql);
	$sth->execute() || Carp::croak("SQL error [$sql] $DBI::errstr");
	my $ret = $sth->fetchrow_array();
	$sth->finish();
	return $ret;

}

sub selall {
	my $self = shift;
	my $sql = shift;
	my $dbh = $self->{dbh};
	my $sth = $dbh->prepare($sql);
	$sth->execute() || Carp::croak("SQL error [$sql] $DBI::errstr");
	my $ret = $sth->fetchall_arrayref({});
	$sth->finish();
	return $ret;

}

1;
