$:.unshift File.expand_path('../lib', __FILE__)

require 'rake'
require 'rake/testtask'
require 'rdoc/task'
require 'rubygems/package_task'
require 'fileutils'
require 'premailer'

def gemspec
 @gemspec ||= begin
   file = File.expand_path('../premailer.gemspec', __FILE__)
   eval(File.read(file), binding, file)
 end
end

Gem::PackageTask.new(gemspec) do |pkg|
  pkg.need_tar = true
end

desc 'Default: parse a URL.'
task :default => [:inline]

desc 'Parse a URL and write out the output.'
task :inline do
  url = ENV['url']
  output = ENV['output']
  
  if !url or url.empty? or !output or output.empty?
    puts 'Usage: rake inline url=http://example.com/ output=output.html'
    exit
  end

  premailer = Premailer.new(url, :warn_level => Premailer::Warnings::SAFE, :verbose => true, :adapter => :nokogiri)
  fout = File.open(output, "w")
  fout.puts premailer.to_inline_css
  fout.close

  puts "Succesfully parsed '#{url}' into '#{output}'"
  puts premailer.warnings.length.to_s + ' CSS warnings were found'
end

task :text do
  url = ENV['url']
  output = ENV['output']
  
  if !url or url.empty? or !output or output.empty?
    puts 'Usage: rake text url=http://example.com/ output=output.txt'
    exit
  end

  premailer = Premailer.new(url, :warn_level => Premailer::Warnings::SAFE)
  fout = File.open(output, "w")
  fout.puts premailer.to_plain_text
  fout.close
  
  puts "Succesfully parsed '#{url}' into '#{output}'"
end

Rake::TestTask.new do |t|
  t.test_files = FileList['test/test_*.rb']
  t.verbose = false
end

RDoc::Task.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc", "LICENSE.rdoc", "lib/**/*.rb")
  rd.title = 'Premailer Documentation'
end
