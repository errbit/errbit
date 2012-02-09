all::
RSYNC_DEST := bogomips.org:/srv/bogomips/kgio
rfproject := rainbows
rfpackage := kgio
include pkg.mk
ifneq ($(VERSION),)
release::
	$(RAKE) raa_update VERSION=$(VERSION)
	$(RAKE) publish_news VERSION=$(VERSION)
endif
