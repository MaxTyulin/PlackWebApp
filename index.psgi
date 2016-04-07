use strict;

use Plack;
use Plack::Request;
use Plack::Builder;
use Plack::App::File;

use Template;
use HTTP::Router::Declare;

use lib::Database;
use lib::Model;
use lib::Controller::Todo;

use Data::Dumper;
use Carp;

my $css    = Plack::App::File->new(root => "tpl/css");
my $js     = Plack::App::File->new(root => "tpl/js");


my $router = router {
	    match '/', {method => 'GET'},to {controller => 'lib::Controller::Todo',action => 'index'};
	    match '/todo', {method => 'GET'},to {controller => 'lib::Controller::Todo',action => 'index'};
	    match '/todo', {method => 'POST'},to {controller => 'lib::Controller::Todo',action => 'store'};
};

my $db = lib::Database->new('my.db','test','test') || Carp::croak('failed connect to db');

my $template = Template->new({
	INCLUDE_PATH => 'tpl',
	WRAPPER	=> 'wrapper.tt2',
});

my $model = lib::Model->new($db);

my $app = sub {
	my $env = shift;
	my $req = Plack::Request->new($env);
	my $match = $router->match($req) 
		or return $req->new_response(404)->finalize;
	
	
	my $params = $match->params;
	warn Dumper($params);
	my $ctrl = $params->{controller}->new();
	warn Dumper($ctrl);

	my $action = $ctrl->can($params->{action})
		or return $req->new_response(405)->finalize;

	$ctrl->{Template} = $template;
	$ctrl->{Model} = $model;

	my $res = $ctrl->$action($req,$params);
	return $res->finalize();
};

my $main = builder {
	#enable 'Session', store => 'File';
	#enable "+Middleware::ACL";
	mount "/" => builder {$app};

	mount "/js" => $js;
	mount "/css" => $css;
};
