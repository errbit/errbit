## 0.2.0 - Not released Yet

### Improvements

- Update some gems ([@shingara][])
- [#492][] Improve some Pjax call ([@nfedyashev][])
- [#428][] Add the support of Unfuddle Tracker ([@parallel588][])
- Avoid to delete his own user ([@shingara][])
- [#456][] Avoid to delete admin access of current user logged ([@shingara][])
- [#253][] Refactor the Fingerprint generation ([@boblail][])
- [#508][] Merge comments to when you merge problems ([@shingara][])
- Update the Devise Gem to the last one ([@shingara][])

### Bug Fixes

- [#343][] Fix the ical generation. ([@shingara][])
- [#503][] Fix issue on where the service_url choose never use. ([@nfedyashev][])
- [#506][] Fix issue on bitbucket issue tracker creation failed. ([@Gonzih][])

## 0.1.0 - 2013-05-29

### Improvements

- [#474][] Improve message when access denied. ([@chadcf][])
- [#468][] Launch a repairDatabase in MongoDB database after launching
  the clear_resolved task. ([@shingara][])
- Update gem of Mongoid to 2.7.1
- Update gem of Mongo to 1.8.5
- [#457][] Add task information about db:seed in Readme. ([@mildavw][])
- Add support of Ruby 2.0.0
- [#475][] Return a HTTP 422 status code when you try push notice with
  bad api key. ([@shingara][])
- Return a 400 http status when you try put a notice without args.
  ([@shingara][])
- [#486][] Add confirms box when you do massive action. ([@manuelmeurer][])
- [#487][] Add specific template to redmine notification with less useless data. ([@tvdeyen][])

### Bug fixes

- [#469][] Fix issue about the documentation of new heroku addons usage.
  ([@adamjt][])
- [#455][] Avoid raising exception if you comment an exception and no
  other user are define to received this comment. ([@alvarobp][])
- [#453][] Fix ruby 2.0.0 incompatibilities with gem ([@SamSaffron][])
- [#476][] Fix javascript notifier issue with IE8 ([@sdepold][])
- [#466][] Fix not see problem if octokit gem not define ([@tamaloa][])
- [#460][] Fix issue when you try see user with gravatar activate but no
  email define to this user ([@ivanyv][])
- [#478][] Fix issue about calculation of statisque of problem after
  merge ([@shingara][])

<!-- Issue fix -->

[#253]: https://github.com/errbit/errbit/issues/253
[#343]: https://github.com/errbit/errbit/issues/343
[#428]: https://github.com/errbit/errbit/issues/428
[#453]: https://github.com/errbit/errbit/issues/453
[#455]: https://github.com/errbit/errbit/issues/455
[#456]: https://github.com/errbit/errbit/issues/456
[#457]: https://github.com/errbit/errbit/issues/457
[#460]: https://github.com/errbit/errbit/issues/460
[#466]: https://github.com/errbit/errbit/issues/466
[#468]: https://github.com/errbit/errbit/issues/468
[#469]: https://github.com/errbit/errbit/issues/469
[#474]: https://github.com/errbit/errbit/issues/474
[#475]: https://github.com/errbit/errbit/issues/475
[#476]: https://github.com/errbit/errbit/issues/476
[#478]: https://github.com/errbit/errbit/issues/478
[#487]: https://github.com/errbit/errbit/issues/487
[#486]: https://github.com/errbit/errbit/issues/486
[#492]: https://github.com/errbit/errbit/issues/492
[#503]: https://github.com/errbit/errbit/issues/503
[#506]: https://github.com/errbit/errbit/issues/506
[#508]: https://github.com/errbit/errbit/issues/508

<!-- Contributor on Errbit Thanks to all of them -->

[@SamSaffron]: https://github.com/SamSaffron
[@adamjt]: https://github.com/adamjt
[@alvarobp]: https://github.com/alvarobp
[@chadcf]: https://github.com/chadcf
[@mildavw]: https://github.com/mildavw
[@sdepold]: https://github.com/sdepold
[@shingara]: https://github.com/shingara
[@tamaloa]: https://github.com/tamaloa
[@ivanyv]: https://github.com/ivanyv
[@manuelmeurer]: https://github.com/manuelmeurer
[@tvdeyen]: https://github.com/tvdeyen
[@nfedyashev]: https://github.com/nfedyashev
[@parallel588]: https://github.com/parallel588
[@Gonzih]: https://github.com/Gonzih
[@boblail]: https://github.com/boblail
