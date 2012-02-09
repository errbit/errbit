desc "Instructions on how to contribute to launchy"
task :help do
  abort <<-_banner
-----------------------------------------------------------------------
  I see you are wanting to do some development on launchy. You will 
  need to install the 'bones' gem first.

     % gem install bones -v #{USING_BONES_VERSION}

  The easiest way to start after that is with the 
  'install:dependencies' task:

     % rake gem:install_dependencies

  If you use bundler, then you will need to first create the Gemfile 
  and then run 'bundle install':

     % rake bundle:gemfile
     % bundle install

  Now you are ready to work on launchy.  Please submit bugs and pull 
  requests to:

    https://github.com/copiousfreetime/launchy

  Thanks!

     -jeremy
-----------------------------------------------------------------------
_banner
end

desc "(Alias for 'help') Instructions on how to contribute to launchy"
task 'how_to_contribute' => :help
desc "(Alias for 'help') Instructions on how to contribute to launchy"
task '==> I WANT TO CONTRIBUTE <==' => :help
