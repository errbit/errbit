# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "kgio"
  s.version = "2.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["kgio hackers"]
  s.date = "2011-07-15"
  s.description = "kgio provides non-blocking I/O methods for Ruby without raising\nexceptions on EAGAIN and EINPROGRESS.  It is intended for use with the\nUnicorn and Rainbows! Rack servers, but may be used by other\napplications (that run on Unix-like platforms)."
  s.email = "kgio@librelist.org"
  s.extensions = ["ext/kgio/extconf.rb"]
  s.extra_rdoc_files = ["LICENSE", "README", "TODO", "NEWS", "LATEST", "ChangeLog", "ISSUES", "HACKING", "lib/kgio.rb", "ext/kgio/accept.c", "ext/kgio/autopush.c", "ext/kgio/connect.c", "ext/kgio/kgio_ext.c", "ext/kgio/poll.c", "ext/kgio/read_write.c", "ext/kgio/wait.c", "ext/kgio/tryopen.c"]
  s.files = ["LICENSE", "README", "TODO", "NEWS", "LATEST", "ChangeLog", "ISSUES", "HACKING", "lib/kgio.rb", "ext/kgio/accept.c", "ext/kgio/autopush.c", "ext/kgio/connect.c", "ext/kgio/kgio_ext.c", "ext/kgio/poll.c", "ext/kgio/read_write.c", "ext/kgio/wait.c", "ext/kgio/tryopen.c", "ext/kgio/extconf.rb"]
  s.homepage = "http://bogomips.org/kgio/"
  s.rdoc_options = ["-t", "kgio - kinder, gentler I/O for Ruby", "-W", "http://bogomips.org/kgio.git/tree/%s"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "rainbows"
  s.rubygems_version = "1.8.15"
  s.summary = "kinder, gentler I/O for Ruby"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<wrongdoc>, ["~> 1.5"])
      s.add_development_dependency(%q<strace_me>, ["~> 1.0"])
    else
      s.add_dependency(%q<wrongdoc>, ["~> 1.5"])
      s.add_dependency(%q<strace_me>, ["~> 1.0"])
    end
  else
    s.add_dependency(%q<wrongdoc>, ["~> 1.5"])
    s.add_dependency(%q<strace_me>, ["~> 1.0"])
  end
end
