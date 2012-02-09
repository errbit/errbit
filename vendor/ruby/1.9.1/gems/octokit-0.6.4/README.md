Octokit
=======
Simple Ruby wrapper for the GitHub v2 API.

![The Puppeteer](https://github.com/pengwynn/octokit/raw/master/puppeteer.jpg "The Puppeteer") by [![Cameron McEfee)](https://secure.gravatar.com/avatar/a79ff2bb7da84e275361857d2feb2b1b?s=20 "Cameron McEfee")](https://github.com/cameronmcefee)

Installation
------------
    gem install octokit

Continuous Integration
----------------------
[![Build Status](http://travis-ci.org/pengwynn/octokit.png)](http://travis-ci.org/pengwynn/octokit)

Documentation
-------------
http://rdoc.info/gems/octokit

Examples
-------------

### Show a user

    Octokit.user("sferik")
    => <#Hashie::Rash blog="http://twitter.com/sferik" company="Code for America" created_at="2008/05/14 13:36:12 -0700" email="sferik@gmail.com" followers_count=177 following_count=83 gravatar_id="1f74b13f1e5c6c69cb5d7fbaabb1e2cb" id=10308 location="San Francisco" login="sferik" name="Erik Michaels-Ober" permission=nil public_gist_count=16 public_repo_count=30 type="User">

### Show who a user follows

    Octokit.following("sferik")
    => ["rails", "puls", "wycats", "dhh", "jm3", "joshsusser", "nkallen", "technoweenie", "blaine", "al3x", "defunkt", "schacon", "bmizerany", "rtomayko", "jpr5", "lholden", "140proof", "ephramzerb", "carlhuda", "carllerche", "jnunemaker", "josh", "hoverbird", "jamiew", "jeremyevans", "brynary", "mojodna", "mojombo", "joshbuddy", "igrigorik", "perplexes", "joearasin", "hassox", "nickmarden", "pengwynn", "mmcgrana", "reddavis", "reinh", "mzsanford", "aanand", "pjhyett", "kneath", "tekkub", "adamstac", "timtrueman", "aaronblohowiak", "josevalim", "kaapa", "hurrycane", "jackdempsey", "drogus", "cameronpriest", "danmelton", "marcel", "r", "atmos", "mbleigh", "isaacs", "maxogden", "codeforamerica", "chadk", "laserlemon", "gruber", "lsegal", "bblimke", "wayneeseguin", "brixen", "dkubb", "bhb", "bcardarella", "elliottcable", "fbjork", "mlightner", "dianakimball", "amerine", "danchoi", "develop", "dmfrancisco", "unruthless", "trotter", "hannestyden", "codahale", "ry"]

### Repositories
For convenience, methods that require a repoistory argument may be passed in any of the following forms:

* "pengwynn/octokit"
* {:username => "pengwynn", :name => "octokit"}
* {:username => "pengwynn", :repo => "octokit"}
* instance of `Repository`

    Octokit.repo("pengwynn/octokit")
    => <#Hashie::Rash created_at="2009/12/10 13:41:49 -0800" description="Simple Ruby wrapper for the GitHub v2 API and feeds" fork=false forks=25 has_downloads=true has_issues=true has_wiki=true homepage="http://wynnnetherland.com/projects/octokit" integrate_branch="master" language="Ruby" name="octokit" open_issues=8 owner="pengwynn" private=false pushed_at="2011/05/05 10:48:57 -0700" size=1804 url="https://github.com/pengwynn/octokit" watchers=92>

Authenticated requests
----------------------
Some methods require authentication so you'll need to pass a login and an api_token. You can find your GitHub API token on your [account page](https://github.com/account).

    client = Octokit::Client.new(:login => "pengwynn", :token => "OU812")
    client.follow!("sferik")

Submitting a Pull Request
-------------------------
1. Fork the project.
2. Create a topic branch.
3. Implement your feature or bug fix.
4. Add documentation for your feature or bug fix.
5. Run <tt>bundle exec rake doc:yard</tt>. If your changes are not 100% documented, go back to step 4.
6. Add specs for your feature or bug fix.
7. Run <tt>bundle exec rake spec</tt>. If your changes are not 100% covered, go back to step 6.
8. Commit and push your changes.
9. Submit a pull request. Please do not include changes to the version or gemspec. (If you want to create your own version for some reason, please do so in a separate commit.)

Inspiration
-----------
Octokit was inspired by [Octopi](https://github.com/fcoury/octopi) and aims to be a lightweight, less-ActiveResourcey alternative.

Copyright
---------
Copyright (c) 2011 [Wynn Netherland](http://wynnnetherland.com), [Adam Stacoviak](http://adamstacoviak.com/), [Erik Michaels-Ober](https://github.com/sferik).
See [LICENSE](https://github.com/pengwynn/octokit/blob/master/LICENSE) for details.
