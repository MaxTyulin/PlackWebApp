package lib::Model::Todo;
use strict;
use warnings;
use Data::Dumper;

my $db;

sub new {
	my $class = shift;
	my $db = shift;
	my $self = bless {}, $class;
	$self->{db} = $db;
	return $self;
}

sub get_list {
	my $self = shift;
	my $params = shift;
	
	my $limit = $params->{limit} || 20; #записей на страницу, по умолчанию 20
	my $offset = $params->{offset} || 0;
	my $order = $params->{order} || 'ID';

	#выбираем задачи из базы
	my $list = $self->{db}->selall("SELECT ID,isDone,TDName,TDDate FROM todo ORDER BY $order LIMIT $limit OFFSET $offset");
	return $list;

}

1;
