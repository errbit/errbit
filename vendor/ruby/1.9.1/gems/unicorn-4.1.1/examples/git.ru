#\-E none

# See http://thread.gmane.org/gmane.comp.web.curl.general/10473/raw on
# how to setup git for this.  A better version of the above patch was
# accepted and committed on June 15, 2009, so you can pull the latest
# curl CVS snapshot to try this out.
require 'unicorn/app/inetd'

use Rack::Lint
use Rack::Chunked # important!
run Unicorn::App::Inetd.new(
 *%w(git daemon --verbose --inetd --export-all --base-path=/home/ew/unicorn)
)
