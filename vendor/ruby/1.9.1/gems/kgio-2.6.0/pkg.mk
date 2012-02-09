RUBY = ruby
RAKE = rake
RSYNC = rsync
WRONGDOC = wrongdoc

GIT-VERSION-FILE: .FORCE-GIT-VERSION-FILE
	@./GIT-VERSION-GEN
-include GIT-VERSION-FILE
-include local.mk
DLEXT := $(shell $(RUBY) -rrbconfig -e 'puts RbConfig::CONFIG["DLEXT"]')
RUBY_VERSION := $(shell $(RUBY) -e 'puts RUBY_VERSION')
RUBY_ENGINE := $(shell $(RUBY) -e 'puts((RUBY_ENGINE rescue "ruby"))')
lib := lib

ifeq ($(shell test -f script/isolate_for_tests && echo t),t)
isolate_libs := tmp/isolate/$(RUBY_ENGINE)-$(RUBY_VERSION)/isolate.mk
$(isolate_libs): script/isolate_for_tests
	@$(RUBY) script/isolate_for_tests
-include $(isolate_libs)
lib := $(lib):$(ISOLATE_LIBS)
endif

ext := $(firstword $(wildcard ext/*))
ifneq ($(ext),)
ext_pfx := tmp/ext/$(RUBY_ENGINE)-$(RUBY_VERSION)
ext_h := $(wildcard $(ext)/*/*.h $(ext)/*.h)
ext_src := $(wildcard $(ext)/*.c $(ext_h))
ext_pfx_src := $(addprefix $(ext_pfx)/,$(ext_src))
ext_d := $(ext_pfx)/$(ext)/.d
$(ext)/extconf.rb: $(wildcard $(ext)/*.h)
	@>> $@
$(ext_d):
	@mkdir -p $(@D)
	@> $@
$(ext_pfx)/$(ext)/%: $(ext)/% $(ext_d)
	install -m 644 $< $@
$(ext_pfx)/$(ext)/Makefile: $(ext)/extconf.rb $(ext_d) $(ext_h)
	$(RM) -f $(@D)/*.o
	cd $(@D) && $(RUBY) $(CURDIR)/$(ext)/extconf.rb
ext_sfx := _ext.$(DLEXT)
ext_dl := $(ext_pfx)/$(ext)/$(notdir $(ext)_ext.$(DLEXT))
$(ext_dl): $(ext_src) $(ext_pfx_src) $(ext_pfx)/$(ext)/Makefile
	@echo $^ == $@
	$(MAKE) -C $(@D)
lib := $(lib):$(ext_pfx)/$(ext)
build: $(ext_dl)
else
build:
endif

pkg_extra += GIT-VERSION-FILE NEWS ChangeLog LATEST
ChangeLog: GIT-VERSION-FILE .wrongdoc.yml
	$(WRONGDOC) prepare
NEWS LATEST: ChangeLog

manifest:
	$(RM) .manifest
	$(MAKE) .manifest

.manifest: $(pkg_extra)
	(git ls-files && for i in $@ $(pkg_extra); do echo $$i; done) | \
		LC_ALL=C sort > $@+
	cmp $@+ $@ || mv $@+ $@
	$(RM) $@+

doc:: .document .wrongdoc.yml $(pkg_extra)
	-find lib -type f -name '*.rbc' -exec rm -f '{}' ';'
	-find ext -type f -name '*.rbc' -exec rm -f '{}' ';'
	$(RM) -r doc
	$(WRONGDOC) all
	install -m644 COPYING doc/COPYING
	install -m644 $(shell LC_ALL=C grep '^[A-Z]' .document) doc/

ifneq ($(VERSION),)
pkggem := pkg/$(rfpackage)-$(VERSION).gem
pkgtgz := pkg/$(rfpackage)-$(VERSION).tgz
release_notes := release_notes-$(VERSION)
release_changes := release_changes-$(VERSION)

release-notes: $(release_notes)
release-changes: $(release_changes)
$(release_changes):
	$(WRONGDOC) release_changes > $@+
	$(VISUAL) $@+ && test -s $@+ && mv $@+ $@
$(release_notes):
	$(WRONGDOC) release_notes > $@+
	$(VISUAL) $@+ && test -s $@+ && mv $@+ $@

# ensures we're actually on the tagged $(VERSION), only used for release
verify:
	test x"$(shell umask)" = x0022
	git rev-parse --verify refs/tags/v$(VERSION)^{}
	git diff-index --quiet HEAD^0
	test $$(git rev-parse --verify HEAD^0) = \
	     $$(git rev-parse --verify refs/tags/v$(VERSION)^{})

fix-perms:
	-git ls-tree -r HEAD | awk '/^100644 / {print $$NF}' | xargs chmod 644
	-git ls-tree -r HEAD | awk '/^100755 / {print $$NF}' | xargs chmod 755

gem: $(pkggem)

install-gem: $(pkggem)
	gem install $(CURDIR)/$<

$(pkggem): manifest fix-perms
	gem build $(rfpackage).gemspec
	mkdir -p pkg
	mv $(@F) $@

$(pkgtgz): distdir = $(basename $@)
$(pkgtgz): HEAD = v$(VERSION)
$(pkgtgz): manifest fix-perms
	@test -n "$(distdir)"
	$(RM) -r $(distdir)
	mkdir -p $(distdir)
	tar cf - $$(cat .manifest) | (cd $(distdir) && tar xf -)
	cd pkg && tar cf - $(basename $(@F)) | gzip -9 > $(@F)+
	mv $@+ $@

package: $(pkgtgz) $(pkggem)

test-release:: verify package $(release_notes) $(release_changes)
	# make tgz release on RubyForge
	@echo rubyforge add_release -f \
	  -n $(release_notes) -a $(release_changes) \
	  $(rfproject) $(rfpackage) $(VERSION) $(pkgtgz)
	@echo gem push $(pkggem)
	@echo rubyforge add_file \
	  $(rfproject) $(rfpackage) $(VERSION) $(pkggem)
release:: verify package $(release_notes) $(release_changes)
	# make tgz release on RubyForge
	rubyforge add_release -f -n $(release_notes) -a $(release_changes) \
	  $(rfproject) $(rfpackage) $(VERSION) $(pkgtgz)
	# push gem to RubyGems.org
	gem push $(pkggem)
	# in case of gem downloads from RubyForge releases page
	rubyforge add_file \
	  $(rfproject) $(rfpackage) $(VERSION) $(pkggem)
else
gem install-gem: GIT-VERSION-FILE
	$(MAKE) $@ VERSION=$(GIT_VERSION)
endif

all:: test
test_units := $(wildcard test/test_*.rb)
test: test-unit
test-unit: $(test_units)
$(test_units): build
	$(RUBY) -I $(lib) $@ $(RUBY_TEST_OPTS)

# this requires GNU coreutils variants
ifneq ($(RSYNC_DEST),)
publish_doc:
	-git set-file-times
	$(MAKE) doc
	find doc/images -type f | \
		TZ=UTC xargs touch -d '1970-01-01 00:00:06' doc/rdoc.css
	$(MAKE) doc_gz
	$(RSYNC) -av doc/ $(RSYNC_DEST)/
	git ls-files | xargs touch
endif

# Create gzip variants of the same timestamp as the original so nginx
# "gzip_static on" can serve the gzipped versions directly.
doc_gz: docs = $(shell find doc -type f ! -regex '^.*\.\(gif\|jpg\|png\|gz\)$$')
doc_gz:
	for i in $(docs); do \
	  gzip --rsyncable -9 < $$i > $$i.gz; touch -r $$i $$i.gz; done
check-warnings:
	@(for i in $$(git ls-files '*.rb'| grep -v '^setup\.rb$$'); \
	  do $(RUBY) -d -W2 -c $$i; done) | grep -v '^Syntax OK$$' || :

.PHONY: all .FORCE-GIT-VERSION-FILE doc test $(test_units) manifest
.PHONY: check-warnings
