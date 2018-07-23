### Upgrading errbit beyond v0.4.0

* You must have already run migrations at least up to v0.3.0. Check to
  make sure you're schema version is at least 20131011155638 by running rake
  db:version before you upgrade beyond v0.4.0
* Notice fingerprinting has changed and is now easy to configure. But this
  means you'll have to regenerate fingerprints on old notices in order to for
  them to be properly grouped with new notices. To do this run: `rake
  errbit:notice_refingerprint`. If you were using a custom fingerprinter class
  in a previous version, be aware that it will no longer have any effect.
  Fingerprinting is now configurable within the Errbit UI.
* Prior to v0.4.0, users were only able to see apps they were watching.  All
  users can now see all apps and they can watch or unwatch any app. If you were
  using the watch feature to hide secret apps, you should not upgrade beyond
  v0.4.0.

### Upgrading errbit from v0.3.0 to v0.4.0

* All configuration is now done through the environment. See
  [configuration](docs/configuration.md)
* Ruby 1.9 and 2.0 are no longer offically supported. Please upgrade to Ruby
  2.1+
* Errbit now maintains an issue tracker only for github. If you're using
  another issue tracker integration, you may need to maintain it yourself. See
  [Issue Trackers](#issue-trackers)
