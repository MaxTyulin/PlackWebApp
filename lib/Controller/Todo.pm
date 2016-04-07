package lib::Controller::Todo;
use strict;
use warnings;
use Data::Dumper;

sub new {
	return bless {}, shift;;
}

sub index {
	my $self = shift;
	my $request = shift;
	my $params = shift;

	my $template = $self->{Template};
	my $db = $self->{db};

	my $todo = $self->{Model}->get_model('Todo');

	my $tasks=$todo->get_list();
	my $page=1;
	my $order = 'ID';

	my $body;
	my $vars = {'tasks' => $tasks,'page'=>$page, 'order'=>$order, 'title' => 'Список задач'};
	$template->process('Todo/list.tt2', $vars, \$body) or warn $template->error;

	my $res = $request->new_response(200);
	$res->body($body);
	return $res;
}

sub store {
	my $self = shift;
	my $request = shift;
	my $params = shift;

	my $res = $request->new_response(200);
	$res->body('store');
	return $res;
}

sub update {
}

sub delete {
}

sub done {
}

sub undone {
}




1;
