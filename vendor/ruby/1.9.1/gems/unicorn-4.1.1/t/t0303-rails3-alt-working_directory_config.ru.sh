#!/bin/sh
. ./test-rails3.sh

t_plan 5 "Rails 3 (beta) inside alt working_directory (w/ config.ru)"

t_begin "setup and start" && {
	unicorn_setup
	rtmpfiles unicorn_config_tmp usocket
	if test -e $usocket
	then
		die "unexpected $usocket"
	fi
	rails3_app=$(cd rails3-app && pwd)
	rm -rf $t_pfx.app
	mkdir $t_pfx.app
	cd $t_pfx.app
	( cd $rails3_app && tar cf - . ) | tar xf -
	$RAKE db:sessions:create
	$RAKE db:migrate
	unicorn_setup
	rm $pid

	echo "#\\--daemonize --host $host --port $port -l $usocket" \
	     >> $t_pfx.app/config.ru

	# we have --host/--port in config.ru instead
	grep -v ^listen $unicorn_config |
	  grep -v ^pid > $unicorn_config_tmp
	echo "working_directory '$t_pfx.app'" >> $unicorn_config_tmp
	cd /
	unicorn_rails -c $unicorn_config_tmp
}

t_begin "pids in the right place" && {
	if test -e $pid
	then
		die "pid=$pid not expected"
	fi

	unicorn_rails_pid="$t_pfx.app/tmp/pids/unicorn.pid"
	unicorn_pid=$(cat $unicorn_rails_pid)
}

t_begin "static file serving works" && {
	test x"$(curl -sSf http://$listen/x.txt)" = xHELLO
}

t_begin "socket created" && {
	test -S $usocket
}

t_begin "killing succeeds" && {
	kill $unicorn_pid
}

t_done
