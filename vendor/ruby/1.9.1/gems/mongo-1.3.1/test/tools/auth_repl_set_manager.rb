require File.join((File.expand_path(File.dirname(__FILE__))), 'repl_set_manager')

class AuthReplSetManager < ReplSetManager
  def initialize(opts={})
    super(opts)

    @key_path = opts[:key_path] || File.join(File.expand_path(File.dirname(__FILE__)), "keyfile.txt")
    system("chmod 600 #{@key_path}")
  end

  def start_cmd(n)
    super + " --keyFile #{@key_path}"
  end
end
