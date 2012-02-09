# use GNU Make to run tests in parallel, and without depending on RubyGems
all:: test

RLFLAGS = -G2

MRI = ruby
RUBY = ruby
RAKE = rake
RAGEL = ragel
RSYNC = rsync

GIT-VERSION-FILE: .FORCE-GIT-VERSION-FILE
	@./GIT-VERSION-GEN
-include GIT-VERSION-FILE
-include local.mk
ruby_bin := $(shell which $(RUBY))
ifeq ($(DLEXT),) # "so" for Linux
  DLEXT := $(shell $(RUBY) -rrbconfig -e 'puts RbConfig::CONFIG["DLEXT"]')
endif
ifeq ($(RUBY_VERSION),)
  RUBY_VERSION := $(shell $(RUBY) -e 'puts RUBY_VERSION')
endif

RUBY_ENGINE := $(shell $(RUBY) -e 'puts((RUBY_ENGINE rescue "ruby"))')

isolate_libs := tmp/isolate/$(RUBY_ENGINE)-$(RUBY_VERSION).mk
$(isolate_libs): script/isolate_for_tests
	@$(RUBY) script/isolate_for_tests
-include $(isolate_libs)
MYLIBS = $(RUBYLIB):$(ISOLATE_LIBS)

# dunno how to implement this as concisely in Ruby, and hell, I love awk
awk_slow := awk '/def test_/{print FILENAME"--"$$2".n"}' 2>/dev/null

rails_vers := $(subst test/rails/app-,,$(wildcard test/rails/app-*))
slow_tests := test/unit/test_server.rb test/exec/test_exec.rb \
  test/unit/test_signals.rb test/unit/test_upload.rb
log_suffix = .$(RUBY_ENGINE).$(RUBY_VERSION).log
T_r := $(wildcard test/rails/test*.rb)
T := $(filter-out $(slow_tests) $(T_r), $(wildcard test/*/test*.rb))
T_n := $(shell $(awk_slow) $(slow_tests))
T_log := $(subst .rb,$(log_suffix),$(T))
T_n_log := $(subst .n,$(log_suffix),$(T_n))
T_r_log := $(subst .r,$(log_suffix),$(T_r))
test_prefix = $(CURDIR)/test/$(RUBY_ENGINE)-$(RUBY_VERSION)

ext := ext/unicorn_http
c_files := $(ext)/unicorn_http.c $(ext)/httpdate.c $(wildcard $(ext)/*.h)
rl_files := $(wildcard $(ext)/*.rl)
base_bins := unicorn unicorn_rails
bins := $(addprefix bin/, $(base_bins))
man1_rdoc := $(addsuffix _1, $(base_bins))
man1_bins := $(addsuffix .1, $(base_bins))
man1_paths := $(addprefix man/man1/, $(man1_bins))
rb_files := $(bins) $(shell find lib ext -type f -name '*.rb')
inst_deps := $(c_files) $(rb_files) GNUmakefile test/test_helper.rb

ragel: $(ext)/unicorn_http.c
$(ext)/unicorn_http.c: $(rl_files)
	cd $(@D) && $(RAGEL) unicorn_http.rl -C $(RLFLAGS) -o $(@F)
$(ext)/Makefile: $(ext)/extconf.rb $(c_files)
	cd $(@D) && $(RUBY) extconf.rb
$(ext)/unicorn_http.$(DLEXT): $(ext)/Makefile
	$(MAKE) -C $(@D)
lib/unicorn_http.$(DLEXT): $(ext)/unicorn_http.$(DLEXT)
	@mkdir -p lib
	install -m644 $< $@
http: lib/unicorn_http.$(DLEXT)

test-install: $(test_prefix)/.stamp
$(test_prefix)/.stamp: $(inst_deps)
	mkdir -p $(test_prefix)/.ccache
	tar cf - $(inst_deps) GIT-VERSION-GEN | \
	  (cd $(test_prefix) && tar xf -)
	$(MAKE) -C $(test_prefix) clean
	$(MAKE) -C $(test_prefix) http shebang RUBY="$(RUBY)"
	> $@

# this is only intended to be run within $(test_prefix)
shebang: $(bins)
	$(MRI) -i -p -e '$$_.gsub!(%r{^#!.*$$},"#!$(ruby_bin)")' $^

t_log := $(T_log) $(T_n_log)
test: $(T) $(T_n)
	@cat $(t_log) | $(MRI) test/aggregate.rb
	@$(RM) $(t_log)

test-exec: $(wildcard test/exec/test_*.rb)
test-unit: $(wildcard test/unit/test_*.rb)
$(slow_tests): $(test_prefix)/.stamp
	@$(MAKE) $(shell $(awk_slow) $@)

test-integration: $(test_prefix)/.stamp
	$(MAKE) -C t

test-all: test test-rails test-integration

TEST_OPTS = -v
check_test = grep '0 failures, 0 errors' $(t) >/dev/null
ifndef V
       quiet_pre = @echo '* $(arg)$(extra)';
       quiet_post = >$(t) 2>&1 && $(check_test)
else
       # we can't rely on -o pipefail outside of bash 3+,
       # so we use a stamp file to indicate success and
       # have rm fail if the stamp didn't get created
       stamp = $@$(log_suffix).ok
       quiet_pre = @echo $(RUBY) $(arg) $(TEST_OPTS); ! test -f $(stamp) && (
       quiet_post = && > $(stamp) )2>&1 | tee $(t); \
         rm $(stamp) 2>/dev/null && $(check_test)
endif

# not all systems have setsid(8), we need it because we spam signals
# stupidly in some tests...
rb_setsid := $(RUBY) -e 'Process.setsid' -e 'exec *ARGV'

# TRACER='strace -f -o $(t).strace -s 100000'
run_test = $(quiet_pre) \
  $(rb_setsid) $(TRACER) $(RUBY) -w $(arg) $(TEST_OPTS) $(quiet_post) || \
  (sed "s,^,$(extra): ," >&2 < $(t); exit 1)

%.n: arg = $(subst .n,,$(subst --, -n ,$@))
%.n: t = $(subst .n,$(log_suffix),$@)
%.n: export PATH := $(test_prefix)/bin:$(PATH)
%.n: export RUBYLIB := $(test_prefix):$(test_prefix)/lib:$(MYLIBS)
%.n: $(test_prefix)/.stamp
	$(run_test)

$(T): arg = $@
$(T): t = $(subst .rb,$(log_suffix),$@)
$(T): export PATH := $(test_prefix)/bin:$(PATH)
$(T): export RUBYLIB := $(test_prefix):$(test_prefix)/lib:$(MYLIBS)
$(T): $(test_prefix)/.stamp
	$(run_test)

install: $(bins) $(ext)/unicorn_http.c
	$(prep_setup_rb)
	$(RM) lib/unicorn_http.$(DLEXT)
	$(RM) -r .install-tmp
	mkdir .install-tmp
	cp -p bin/* .install-tmp
	$(RUBY) setup.rb all
	$(RM) $^
	mv .install-tmp/* bin/
	$(RM) -r .install-tmp
	$(prep_setup_rb)

setup_rb_files := .config InstalledFiles
prep_setup_rb := @-$(RM) $(setup_rb_files);$(MAKE) -C $(ext) clean

clean:
	-$(MAKE) -C $(ext) clean
	-$(MAKE) -C Documentation clean
	$(RM) $(ext)/Makefile lib/unicorn_http.$(DLEXT)
	$(RM) $(setup_rb_files) $(t_log)
	$(RM) -r $(test_prefix) man

man html:
	$(MAKE) -C Documentation install-$@

pkg_extra := GIT-VERSION-FILE ChangeLog LATEST NEWS \
             $(ext)/unicorn_http.c $(man1_paths)

ChangeLog: GIT-VERSION-FILE .wrongdoc.yml
	wrongdoc prepare

.manifest: ChangeLog $(ext)/unicorn_http.c man
	(git ls-files && for i in $@ $(pkg_extra); do echo $$i; done) | \
	  LC_ALL=C sort > $@+
	cmp $@+ $@ || mv $@+ $@
	$(RM) $@+

doc: .document $(ext)/unicorn_http.c man html .wrongdoc.yml
	for i in $(man1_rdoc); do echo > $$i; done
	find bin lib -type f -name '*.rbc' -exec rm -f '{}' ';'
	$(RM) -r doc
	wrongdoc all
	install -m644 COPYING doc/COPYING
	install -m644 $(shell LC_ALL=C grep '^[A-Z]' .document) doc/
	install -m644 $(man1_paths) doc/
	tar cf - $$(git ls-files examples/) | (cd doc && tar xf -)
	$(RM) $(man1_rdoc)

# publishes docs to http://unicorn.bogomips.org
publish_doc:
	-git set-file-times
	$(MAKE) doc
	find doc/images -type f | \
		TZ=UTC xargs touch -d '1970-01-01 00:00:02' doc/rdoc.css
	$(MAKE) doc_gz
	chmod 644 $$(find doc -type f)
	$(RSYNC) -av doc/ unicorn.bogomips.org:/srv/unicorn/
	git ls-files | xargs touch

# Create gzip variants of the same timestamp as the original so nginx
# "gzip_static on" can serve the gzipped versions directly.
doc_gz: docs = $(shell find doc -type f ! -regex '^.*\.\(gif\|jpg\|png\|gz\)$$')
doc_gz:
	for i in $(docs); do \
	  gzip --rsyncable -9 < $$i > $$i.gz; touch -r $$i $$i.gz; done

rails_git_url = git://github.com/rails/rails.git
rails_git := vendor/rails.git
$(rails_git)/info/cloned-stamp:
	git clone --mirror -q $(rails_git_url) $(rails_git)
	> $@

$(rails_git)/info/v2.2.3-stamp: $(rails_git)/info/cloned-stamp
	cd $(rails_git) && git fetch
	cd $(rails_git) && git rev-parse --verify refs/tags/v2.2.3
	> $@

rails_tests := $(addsuffix .r,$(addprefix $(T_r).,$(rails_vers)))
test-rails: $(rails_tests)
$(T_r).%.r: t = $(addsuffix $(log_suffix),$@)
$(T_r).%.r: rv = $(subst .r,,$(subst $(T_r).,,$@))
$(T_r).%.r: extra = ' 'v$(rv)
$(T_r).%.r: arg = $(T_r)
$(T_r).%.r: export PATH := $(test_prefix)/bin:$(PATH)
$(T_r).%.r: export RUBYLIB := $(test_prefix):$(test_prefix)/lib:$(MYLIBS)
$(T_r).%.r: export UNICORN_RAILS_TEST_VERSION = $(rv)
$(T_r).%.r: export RAILS_GIT_REPO = $(CURDIR)/$(rails_git)
$(T_r).%.r: $(test_prefix)/.stamp $(rails_git)/info/v2.2.3-stamp
	$(run_test)

ifneq ($(VERSION),)
rfproject := mongrel
rfpackage := unicorn
pkggem := pkg/$(rfpackage)-$(VERSION).gem
pkgtgz := pkg/$(rfpackage)-$(VERSION).tgz
release_notes := release_notes-$(VERSION)
release_changes := release_changes-$(VERSION)

release-notes: $(release_notes)
release-changes: $(release_changes)
$(release_changes):
	wrongdoc release_changes > $@+
	$(VISUAL) $@+ && test -s $@+ && mv $@+ $@
$(release_notes):
	wrongdoc release_notes > $@+
	$(VISUAL) $@+ && test -s $@+ && mv $@+ $@

# ensures we're actually on the tagged $(VERSION), only used for release
verify:
	test x"$(shell umask)" = x0022
	git rev-parse --verify refs/tags/v$(VERSION)^{}
	git diff-index --quiet HEAD^0
	test `git rev-parse --verify HEAD^0` = \
	     `git rev-parse --verify refs/tags/v$(VERSION)^{}`

fix-perms:
	git ls-tree -r HEAD | awk '/^100644 / {print $$NF}' | xargs chmod 644
	git ls-tree -r HEAD | awk '/^100755 / {print $$NF}' | xargs chmod 755

gem: $(pkggem)

install-gem: $(pkggem)
	gem install $(CURDIR)/$<

$(pkggem): .manifest fix-perms
	gem build $(rfpackage).gemspec
	mkdir -p pkg
	mv $(@F) $@

$(pkgtgz): distdir = $(basename $@)
$(pkgtgz): HEAD = v$(VERSION)
$(pkgtgz): .manifest fix-perms
	@test -n "$(distdir)"
	$(RM) -r $(distdir)
	mkdir -p $(distdir)
	tar cf - $$(cat .manifest) | (cd $(distdir) && tar xf -)
	cd pkg && tar cf - $(basename $(@F)) | gzip -9 > $(@F)+
	mv $@+ $@

package: $(pkgtgz) $(pkggem)

release: verify package $(release_notes) $(release_changes)
	# make tgz release on RubyForge
	rubyforge add_release -f -n $(release_notes) -a $(release_changes) \
	  $(rfproject) $(rfpackage) $(VERSION) $(pkgtgz)
	# push gem to Gemcutter
	gem push $(pkggem)
	# in case of gem downloads from RubyForge releases page
	-rubyforge add_file \
	  $(rfproject) $(rfpackage) $(VERSION) $(pkggem)
	$(RAKE) raa_update VERSION=$(VERSION)
	$(RAKE) fm_update VERSION=$(VERSION)
else
gem install-gem: GIT-VERSION-FILE
	$(MAKE) $@ VERSION=$(GIT_VERSION)
endif

.PHONY: .FORCE-GIT-VERSION-FILE doc $(T) $(slow_tests) man
.PHONY: test-install
