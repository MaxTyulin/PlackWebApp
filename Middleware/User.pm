package Middleware::User;
use strict;
use warnings;
use parent qw/Plack::Middleware/;
use Plack;
use Plack::Response;
use Plack::Request;
use Email::Valid;
use Data::Dumper;

sub call {
	my $self = shift;
	my $env = shift;
	my $template = $self->{template};

	my $path = $env->{PATH_INFO} || '';
	$path =~ s/[^a-z]//;
	if ($path eq '') {
		return $self->_list($env);
	} elsif ($path eq 'login') {
		return $self->_login($env);
	} elsif ($path eq 'logout') {
		return $self->_logout($env);
	} else {
		return $self->app->($env);
	}
}


sub _login {
	my $self = shift;
	my $env = shift;
	my $session = $env->{'psgix.session'};
	my $template = $self->{template};
	my $req = Plack::Request->new($env);
	my $params = $req->parameters();
	my $res = $req->new_response(200);

	#проверяем, не залогинен ли пользователь
	my $uid = $session->{'uid'};
	if ($uid) {
		$res->redirect('/');
	}
	
	my $vars = {'title'=>'Вход'};
	if ($params->{'save'}) {
		my $name=$params->{'name'};
		my $email=$params->{'email'};
		
		if ($name eq "") {
			$vars->{error} = "Поле 'Имя' не может быть пустым<br/>";
		} elsif ($name =~ /[^\w\s]/) {
			$vars->{error} = "Поле 'Имя' содержит некорректные символы<br/>Допустимы буквы латинского алфавита, числа, пробел и знак подчеркивания<br/>";
		}


		if ($email eq "") {
			$vars->{error} .= "Поле 'Email' не может быть пустым<br/>";
		} elsif (! Email::Valid->address($email)) {
			$vars->{error} = "Введите корректный email<br/>";
		}

		unless ($vars->{error}) {
			#если данные корректны, сохраняем пользователя
			my @now = localtime;
			my $date = (1900+$now[5])."-".sprintf("%02d",$now[4])."-".sprintf("%02d",$now[3])." ".sprintf("%02d",$now[2]).":".sprintf("%02d",$now[1]).":".sprintf("%02d",$now[0]);
			warn "$date login $name $email";
			$self->{db}->{dbh}->do('INSERT INTO users (Name,Email,RegDate) VALUES (?,?,?)',{},$name,$email,$date);
			$uid =  $self->{db}->select('SELECT last_insert_rowid()');
			if ($uid) {
				$session->{'uid'}=$uid;
				$res->redirect('/');
			} else {
				warn "не удалось добавить пользователя";
			}
		}

	}

	my $body;
	$template->process('login.tt2', $vars, \$body);
	$res->body($body);
	return $res->finalize();
	
}

sub _logout {
	my $self = shift;
	my $env = shift;
	my $req = Plack::Request->new($env);
	my $res = $req->new_response(200);
	my $session = $env->{'psgix.session'};
	my $uid = $session->{'uid'};
	if ($uid) {
		$self->{db}->{dbh}->do('DELETE FROM users WHERE ID=?',{},$uid);
		warn "logout uid $uid";
	}
	$session->{'uid'} = undef;
	$res->redirect('/login');
	return $res->finalize();

}

sub _list {
	my $self = shift;
	my $env = shift;
	
	
	my $template = $self->{template};
	my $req = Plack::Request->new($env);
	my $res = $req->new_response(200);
	
	#проверяем залогинен ли пользователь
	my $session = $env->{'psgix.session'};
	my $uid = $session->{uid};
	#если не залогинен, 
	#отправляем на страницу с аутентификацией
	unless (defined $uid) {
		$res->redirect("/login");
	}


	my $limit = 20; #записей на страницу
	#вычисляем количество страниц и формируем массив со списком страниц
	my $ucount = $self->{db}->select('SELECT COUNT(1) FROM users') || 0;
	my $pcount = $ucount/$limit;
	$pcount = int(++$pcount) if (int($pcount)<$pcount); #если не целочисленное деление, то округляем в большую сторону
	my $params = $req->parameters();
	my $page = (defined $params->{page}) ? $params->{page} : 0;
	$page =~ s/[^0-9]//g;
	$page=$pcount if ($page>$pcount);
	$page=1 if ($page<1);

	my @pages = (1 .. $pcount);
	my $cut=0;
	if ($page>5) { #удаляем страницы в начале
		$cut=$page-4;
		splice(@pages,1,$cut,'...');
	}

	my $position = $page-1;
	my $length = $pcount-$page;
	if ($length > 5) { #удаляем страницы в конце
		$cut-- if ($cut>0);
		splice(@pages,$page+3-$cut,$length-4,'...');
	}


	#определяем порядок сортировки
	my @orders = ('id','name','email','regdate');
	my $order = (defined $params->{order}) ? $params->{order} : 1;
	$order =~ s/[^1-9]//g;
	$order = 1 if ($order eq '');
	$order=1 unless (defined($orders[$order-1]));

	#выбираем пользователей из базы
	my $offset = ($page-1)*$limit;
	my $users = $self->{db}->selall("SELECT ID,Name,Email,RegDate FROM users ORDER BY ".$orders[$order-1]." LIMIT $limit OFFSET $offset");

	my $body;
	my $vars = {'users' => $users,'pages'=> \@pages,'page'=>$page, 'order'=>$order, 'title' => 'Список пользователей'};
	$template->process('list.tt2', $vars, \$body) or warn $template->error;
	$res->body($body);
	return $res->finalize();

}

1;
