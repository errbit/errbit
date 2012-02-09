#!/bin/sh
# Copyright (c) 2009 Rainbows! hackers
# Copyright (c) 2010 Unicorn hackers
. ./my-tap-lib.sh

set +u

# sometimes we rely on http_proxy to avoid wasting bandwidth with Isolate
# and multiple Ruby versions
NO_PROXY=${UNICORN_TEST_ADDR-127.0.0.1}
export NO_PROXY

set -e
RUBY="${RUBY-ruby}"
RUBY_VERSION=${RUBY_VERSION-$($RUBY -e 'puts RUBY_VERSION')}
RUBY_ENGINE=${RUBY_ENGINE-$($RUBY -e 'puts((RUBY_ENGINE rescue "ruby"))')}
t_pfx=$PWD/trash/$T-$RUBY_ENGINE-$RUBY_VERSION
set -u

PATH=$PWD/bin:$PATH
export PATH

test -x $PWD/bin/unused_listen || die "must be run in 't' directory"

wait_for_pid () {
	path="$1"
	nr=30
	while ! test -s "$path" && test $nr -gt 0
	do
		nr=$(($nr - 1))
		sleep 1
	done
}

# given a list of variable names, create temporary files and assign
# the pathnames to those variables
rtmpfiles () {
	for id in "$@"
	do
		name=$id
		_tmp=$t_pfx.$id
		eval "$id=$_tmp"

		case $name in
		*fifo)
			rm -f $_tmp
			mkfifo $_tmp
			T_RM_LIST="$T_RM_LIST $_tmp"
			;;
		*socket)
			rm -f $_tmp
			T_RM_LIST="$T_RM_LIST $_tmp"
			;;
		*)
			> $_tmp
			T_OK_RM_LIST="$T_OK_RM_LIST $_tmp"
			;;
		esac
	done
}

dbgcat () {
	id=$1
	eval '_file=$'$id
	echo "==> $id <=="
	sed -e "s/^/$id:/" < $_file
}

check_stderr () {
	set +u
	_r_err=${1-${r_err}}
	set -u
	if grep -v $T $_r_err | grep -i Error
	then
		die "Errors found in $_r_err"
	elif grep SIGKILL $_r_err
	then
		die "SIGKILL found in $_r_err"
	fi
}

# unicorn_setup
unicorn_setup () {
	eval $(unused_listen)
	port=$(expr $listen : '[^:]*:\([0-9]\+\)')
	host=$(expr $listen : '\([^:]*\):[0-9]\+')

	rtmpfiles unicorn_config pid r_err r_out fifo tmp ok
	cat > $unicorn_config <<EOF
listen "$listen"
pid "$pid"
stderr_path "$r_err"
stdout_path "$r_out"
EOF
}

unicorn_wait_start () {
	# no need to play tricks with FIFOs since we got "ready_pipe" now
	unicorn_pid=$(cat $pid)
}

rsha1 () {
	_cmd="$(which sha1sum 2>/dev/null || :)"
	test -n "$_cmd" || _cmd="$(which openssl 2>/dev/null || :) sha1"
	test "$_cmd" != " sha1" || _cmd="$(which gsha1sum 2>/dev/null || :)"

	# last resort, see comments in sha1sum.rb for reasoning
	test -n "$_cmd" || _cmd=sha1sum.rb
	expr "$($_cmd)" : '\([a-f0-9]\{40\}\)'
}
