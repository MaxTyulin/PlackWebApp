use strict;
use Plack;
use Plack::Request;
use Plack::Builder;
use Middleware::User;
use Plack::App::File;
use Template;
use lib::Database;
use Data::Dumper;
use Carp;

my $css    = Plack::App::File->new(root => "/home/makc/mail/tpl/css");
my $js     = Plack::App::File->new(root => "/home/makc/mail/tpl/js");

my $template = Template->new({
		INCLUDE_PATH => 'tpl',
		WRAPPER	=> 'wrapper.tt2',
		});

my $db = lib::Database->new('my.db','test','test') || Carp::croak('failed connect to db');

my $app = sub {
	my $env = shift;
	my $req = Plack::Request->new($env);
	my $res = $req->new_response(200);
	$res->body('Not Found');
	return $res->finalize();
};

my $main = builder {
	enable 'Session', store => 'File';
	enable "+Middleware::User",template => $template,db => $db;
	mount "/" => builder {$app};
	mount "/js" => $js;
	mount "/css" => $css;
};
