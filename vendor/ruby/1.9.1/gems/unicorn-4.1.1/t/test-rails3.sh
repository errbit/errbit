. ./test-lib.sh
RAILS_VERSION=${RAILS_VERSION-3.0.0}
case $RUBY_VERSION in
1.8.7|1.9.2) ;;
*)
	t_info "RUBY_VERSION=$RUBY_VERSION unsupported for Rails 3"
	exit 0
	;;
esac

arch_gems=../tmp/isolate/ruby-$RUBY_VERSION/gems
rails_gems=../tmp/isolate/rails-$RAILS_VERSION/gems
rails_bin="$rails_gems/rails-$RAILS_VERSION/bin/rails"
if ! test -d "$arch_gems" || ! test -d "$rails_gems" || ! test -x "$rails_bin"
then
	( cd ../ && ./script/isolate_for_tests )
fi

for i in $arch_gems/*-* $rails_gems/*-*
do
	if test -d $i/lib
	then
		RUBYLIB=$(cd $i/lib && pwd):$RUBYLIB
	fi
done

export RUBYLIB
