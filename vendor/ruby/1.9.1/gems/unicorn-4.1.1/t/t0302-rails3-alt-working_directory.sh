#!/bin/sh
. ./test-rails3.sh

t_plan 3 "Rails 3 (beta) inside alt working_directory (no config.ru)"

t_begin "setup and start" && {
	unicorn_setup
	rails3_app=$(cd rails3-app && pwd)
	rm -rf $t_pfx.app
	mkdir $t_pfx.app
	cd $t_pfx.app
	( cd $rails3_app && tar cf - . ) | tar xf -
	rm config.ru
	$RAKE db:sessions:create
	$RAKE db:migrate
	unicorn_setup
	rm $pid
	echo "working_directory '$t_pfx.app'" >> $unicorn_config
	cd /
	unicorn_rails -D -c $unicorn_config
	unicorn_wait_start
}

t_begin "static file serving works" && {
	test x"$(curl -sSf http://$listen/x.txt)" = xHELLO
}

t_begin "killing succeeds" && {
	kill $unicorn_pid
}

t_done
