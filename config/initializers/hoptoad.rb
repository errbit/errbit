require "core_ext/exception"

HoptoadNotifier.configure do |config|
  # Internal Errbit errors are stored locally, but we need
  # to set a dummy API key so that HoptoadNotifier doesn't complain.
  config.api_key = "---------"

  # Don't log error that causes 404 page
  config.ignore << "ActiveRecord::RecordNotFound"
end

# Inform Errbit of the version of the codebase checked out

GIT_COMMIT = ENV.fetch('COMMIT_HASH', `git log -n1 --format='%H'`.chomp).freeze

module SendCommitWithNotice
  def cgi_data
    env = super || {}
    env = env.merge("GIT_COMMIT" => GIT_COMMIT)
    env = env.merge(exception.additional_information) if exception.respond_to?(:additional_information)
    env
  end
end

HoptoadNotifier::Notice.send :prepend, SendCommitWithNotice # <-- NB: requires Ruby 2.0
