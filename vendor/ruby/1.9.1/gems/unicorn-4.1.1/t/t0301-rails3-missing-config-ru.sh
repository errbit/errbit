#!/bin/sh
. ./test-rails3.sh

t_plan 4 "Rails 3 (beta) tests for config.ru haters"

t_begin "setup and start" && {
	rails3_app=$(cd rails3-app && pwd)
	rm -rf $t_pfx.app
	mkdir $t_pfx.app
	cd $t_pfx.app
	( cd $rails3_app && tar cf - . ) | tar xf -
	rm config.ru
	$RAKE db:sessions:create
	$RAKE db:migrate
	unicorn_setup
	unicorn_rails -D -c $unicorn_config
	unicorn_wait_start
}

t_begin "static file serving works" && {
	test x"$(curl -sSf http://$listen/x.txt)" = xHELLO
}

# add more tests here
t_begin "hit with curl" && {
	curl -v http://$listen/ || :
}

t_begin "killing succeeds" && {
	kill $unicorn_pid
}

t_done
