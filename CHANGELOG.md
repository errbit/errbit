## 0.6.?

- update ui to use bootstrap v3 for responsive/mobile devices, includes refactoring
  js and css and adding a couple gems to provide functionality
- fixed issue tracker icons (:goto and :create were swapped)
- added several more translation strings and changed several tests to use them

## 0.6.0
https://github.com/errbit/errbit/issues?utf8=%E2%9C%93&q=milestone%3A0.6.0

## 0.5.0
https://github.com/errbit/errbit/issues?utf8=%E2%9C%93&q=milestone%3A0.5.0

## 0.4.0

- #791 Fix double escaping of problem title in list view.(@felixbuenemann)
- #790 Fix favicon location.(@felixbuenemann)
- #716 Fix inline comments styles.(@oelmekki)
- #778 Update to rails 4.1.(@arthurnn)
- #682 Namespace fingerprint classes better.(@csaunders)
- Drop ruby support for versions 1.9.x, and 2.0.x.(@arthurnn)
- #773 Only leave GitHub issue tracker on vanila errbit, as the others could be
  added just using the plugin.(@arthurnn)
- #768 Update to Mongoid 4.0 and rails to 4.0 (@arthurnn)
- #820 Environment-only configuration

## 0.3.0

### Improvements

- [#515][] Update to Mongoid 3.1 ([@arthurnn][], [@shingara][])
- Drop the 1.8 support
- [#289][] Add unwatch button on App view ([@numbata][], [@shingara][])
- Add autofocus on email login page ([@shingara][])
- Update Gem ([@arthurnn][], [@shingara][])
- [#547][] Add capabilities to admin to regenerate the API key of his
  app ([@shingara][])
- Add environement variable configuration to change the ruby version to
  use ([@shingara][])
- [#588][] Change documentation to see Airbrake gem instead of
  hoptoad_nofier ([@ugisozols][])
- [#592][] Avoid taskmapper dependencies ([@arthurnn][])
- [#597][] Improve fingerprinting if only change by object memory adress
  ([@1st8][])
- [#603][] Improve the page rendering of App list ([@arthurnn][])
- [#606][] Add ability to deploy on Cloud 66 ([@pkallberg][])
- [#613][] Improve text about delete thing ([@mildavw][])
- [#616][] Improvement about our test suite ([@durrantm][])
- [#620][] Add App version information in email notification
  ([@soberstadt][])
- [#624][] Allow configuration of port if errbit not on 80
  ([@rsutphin][])
- [#617][] Allow GET request on notice API ([@soberstadt][])
- [#618][] Improve the stack information in JS notifier ([@soberstadt][])
- [#619][] Handle the App version information in the API ([@soberstadt][])

### Bug Fixes

- [#565][] Treat request URL as CDATA so query string params don't
  result in invalid XML ([@mildavw][])
- [#594][] Dont use ^ and $ on email_regexp([@arthurnn][])
- [#598][] Fix issue about gitlab integration ([@jozefvaclavik][])
- [#609][] Fix issue about page system on search error ([@zhekanax][])
- [#611][] Fix issue about select all error in search page ([@zhekanax][])
- [#615][] Fix some LDAP information in README ([@felixbuenemann][])


[@arthurnn]: https://github.com/arthurnn
[@mildavw]: https://github.com/mildavw
[@numbata]: https://github.com/numbata
[@shingara]: https://github.com/shingara
[@ugisozols]: https://github.com/ugisozols
[@1st8]: https://github.com/1st8
[@jozefvaclavik]: https://github.com/jozefvaclavik
[@zhekanax]: https://github.com/zhekanax
[@pkallberg]: https://github.com/pkallberg
[@durrantm]: https://github.com/durrantm
[@felixbuenemann]: https://github.com/felixbuenemann
[@soberstadt]: https://github.com/soberstadt
[@rsutphin]: https://github.com/rsutphin

[#289]: https://github.com/errbit/errbit/issues/289
[#515]: https://github.com/errbit/errbit/issues/515
[#547]: https://github.com/errbit/errbit/issues/547
[#565]: https://github.com/errbit/errbit/issues/565
[#588]: https://github.com/errbit/errbit/issues/588
[#592]: https://github.com/errbit/errbit/pull/592
[#594]: https://github.com/errbit/errbit/pull/594
[#597]: https://github.com/errbit/errbit/pull/597
[#598]: https://github.com/errbit/errbit/pull/598
[#603]: https://github.com/errbit/errbit/pull/603
[#606]: https://github.com/errbit/errbit/pull/606
[#609]: https://github.com/errbit/errbit/pull/609
[#611]: https://github.com/errbit/errbit/pull/611
[#613]: https://github.com/errbit/errbit/pull/613
[#616]: https://github.com/errbit/errbit/pull/616
[#615]: https://github.com/errbit/errbit/pull/615
[#617]: https://github.com/errbit/errbit/pull/617
[#618]: https://github.com/errbit/errbit/pull/618
[#619]: https://github.com/errbit/errbit/pull/619
[#620]: https://github.com/errbit/errbit/pull/620
[#624]: https://github.com/errbit/errbit/pull/624

## 0.2.1 - Not released Yet

### Improvements

- [#552][] Limite size of asset on errbit ([@tscolari][])
- [#562][] See the version number of errbit on footer ([@nashby][])
- [#555][] Avoid same group by same error if other line of backtrace
  instead of first change ([@shingara][])

### Bug Fixes

- [#558][] Avoid failure if you remote bitbucket_rest_api gem
  ([@shingara][])
- [#559][] Fix some issue on the migration with old database
  ([@shingara][])

[@nashby]: https://github.com/nashby
[@shingara]: https://github.com/shingara
[@tscolari]: https://github.com/tscolari

[#552]: https://github.com/errbit/errbit/issues/552
[#558]: https://github.com/errbit/errbit/issues/558
[#562]: https://github.com/errbit/errbit/issues/562

## 0.2.0 - 2013-09-11

### Improvements

- Update some gems ([@shingara][])
- [#492][] Improve some Pjax call ([@nfedyashev][])
- [#428][] Add the support of Unfuddle Issue Tracker ([@parallel588][])
- Avoid to delete his own user ([@shingara][])
- [#456][] Avoid to delete admin access of current user logged ([@shingara][])
- [#253][] Refactor the Fingerprint generation ([@boblail][])
- [#508][] Merge comments to when you merge problems ([@shingara][])
- Update the Devise Gem to the last one ([@shingara][])
- [#524][] Add current user information on the notifer.js ([@roryf][])
- [#523][] Update javascript-stacktrace ([@aliscott][])
- [#516][] Add Jira Issue tracker ([@xenji][])
- [#512][] Add capabilities to configure the use of sendmail to send
  email from Errbit ([@shingara][])
- [#532][] Use https link in Gravatar if you use errbit on https
  ([@jeroenj][])
- [#536][] Order app by name by default ([@2called-chaos][])
- [#542][] Allow the MONGODB_URL env configuration about Mongodb ([@bacongobbler][])
- [#530][] Improve the flowdock notification ([@nfedyashev][])
- [#531][] Improve the HipChat notification message ([@brendonrapp][])


### Bug Fixes

- [#343][] Fix the ical generation. ([@shingara][])
- [#503][] Fix issue on where the service_url choose never use. ([@nfedyashev][])
- [#506][] Fix issue on bitbucket issue tracker creation failed. ([@Gonzih][])
- [#514][] Add CDATA in xml return by Javascript. ([@mildavw][])
- [#517][] Javascript escape path from javascript Notifier. ([@roryf][])
- [#518][] Fix issue when you try launch task errbit:db:update_update_problem_attrs. ([@shingara][])
- [#526][] Fix issue of pagination after search. ([@shingara][])
- [#528][] Fix issue of action after search. ([@shingara][])

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
[#514]: https://github.com/errbit/errbit/issues/514
[#516]: https://github.com/errbit/errbit/issues/516
[#517]: https://github.com/errbit/errbit/issues/517
[#524]: https://github.com/errbit/errbit/issues/524
[#526]: https://github.com/errbit/errbit/issues/526
[#528]: https://github.com/errbit/errbit/issues/528
[#530]: https://github.com/errbit/errbit/issues/530
[#531]: https://github.com/errbit/errbit/issues/531
[#532]: https://github.com/errbit/errbit/issues/532
[#542]: https://github.com/errbit/errbit/issues/542

<!-- Contributor on Errbit Thanks to all of them -->

[@2called-chaos]: https://github.com/2called-chaos
[@Gonzih]: https://github.com/Gonzih
[@SamSaffron]: https://github.com/SamSaffron
[@adamjt]: https://github.com/adamjt
[@aliscott]: http://github.com/aliscott
[@alvarobp]: https://github.com/alvarobp
[@arthurnn]: https://github.com/arthurnn
[@bacongobbler]: https://github.com/bacongobbler
[@boblail]: https://github.com/boblail
[@brendonrapp]: https://github.com/brendonrapp
[@chadcf]: https://github.com/chadcf
[@ivanyv]: https://github.com/ivanyv
[@jeroenj]: https://github.com/jeroenj
[@manuelmeurer]: https://github.com/manuelmeurer
[@mildavw]: https://github.com/mildavw
[@mildavw]: https://github.com/mildavw
[@nfedyashev]: https://github.com/nfedyashev
[@parallel588]: https://github.com/parallel588
[@roryf]: https://github.com/roryf
[@sdepold]: https://github.com/sdepold
[@shingara]: https://github.com/shingara
[@tamaloa]: https://github.com/tamaloa
[@tvdeyen]: https://github.com/tvdeyen
[@williamn]: https://github.com/williamn
[@xenji]: https://github.com/xenji
