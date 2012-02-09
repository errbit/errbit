require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lighthouse'))
puts <<-TXT
Ruby lib for working with the Lighthouse API's XML interface.  
The first thing you need to set is the account name.  This is the same
as the web address for your account.

  Lighthouse.account = 'activereload'

Then, you should set the authentication.  You can either use your login
credentials with HTTP Basic Authentication or with an API Tokens.  You can
find more info on tokens at http://lighthouseapp.com/help/using-beacons.

  # with basic authentication
  Lighthouse.authenticate('rick@techno-weenie.net', 'spacemonkey')

  # or, use a token
  Lighthouse.token = 'abcdefg'

If no token or authentication info is given, you'll only be granted public access.

This library is a small wrapper around the REST interface.  You should read the docs at
http://lighthouseapp.com/api.
TXT

include Lighthouse