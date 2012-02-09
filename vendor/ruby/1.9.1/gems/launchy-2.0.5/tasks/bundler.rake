namespace :bundle do

  file 'Gemfile' => [ 'gem:spec' ] do
    File.open( 'Gemfile', 'w+' ) do |f|
      f.puts 'source "http://rubygems.org"'
      f.puts 'gemspec'
    end
  end

  desc "Create a bundler Gemfile"
  task :gemfile => 'Gemfile'

end
