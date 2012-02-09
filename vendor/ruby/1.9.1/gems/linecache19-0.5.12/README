= LineCache - A module to read and cache file information of a Ruby program.

== SYNOPSIS

The LineCache module allows one to get any line from any file, caching
the lines and file information on first access to the file. Although
the file may be any file, the common use is when the file is a Ruby
script since parsing of the file is done to figure out where the
statement boundaries are.

The routines here may be is useful when a small random sets of lines
are read from a single file, in particular in a debugger to show
source lines.

== Summary

  require 'linecache'
  lines = LineCache::getlines('/tmp/myruby.rb')
  # The following lines have same effect as the above.
  $: << '/tmp'
  Dir.chdir('/tmp') {lines = LineCache::getlines('myruby.rb')

  line = LineCache::getline('/tmp/myruby.rb', 6)
  # Note lines[6] == line (if /tmp/myruby.rb has 6 lines)

  LineCache::clear_file_cache
  LineCache::clear_file_cache('/tmp/myruby.rb')
  LineCache::update_cache   # Check for modifications of all cached files.

== Credits

  This is a port of the module of the same name from the Python distribution.

  The idea for how TraceLineNumbers works, and some code was taken
  from ParseTree by Ryan Davis.

== Other stuff

Author::   Rocky Bernstein <rockyb@rubyforge.net>
License::  Copyright (c) 2007, 2008 Rocky Bernstein
           Released under the GNU GPL 2 license

== Warranty

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

$Id$
