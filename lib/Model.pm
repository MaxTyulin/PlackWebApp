package lib::Model;

use strict;
use Module::Load;

my %models = ();
my $db;

sub new {
	my $class = shift;
	my $db = shift;
	my $self = bless {},$class;
	$self->{db}=$db;
	return $self;
}

sub get_model {
	my $self = shift;
	my $model = shift;
	#если модель еще не загружена
	unless (exists($models{$model})) {
		#загружаем модель
		autoload 'lib::Model::'.$model;
		my $m = 'lib::Model::'.$model;
		$models{$model} = $m->new($self->{db});
	}

	return $models{$model};
}

1;
