#!/usr/bin/env ruby

require 'rbconfig'

require 'mkmf'

if defined?(CFLAGS)
  if CFLAGS.index(CONFIG['CCDLFLAGS'])
    $CFLAGS = CFLAGS + ' ' + CONFIG['CCDLFLAGS']
  else
    $CFLAGS = CFLAGS
  end
else
  $CFLAGS = CONFIG['CFLAGS']
end
$LDFLAGS = CONFIG['LDFLAGS']
$LIBPATH.push(Config::CONFIG['libdir'])

def crash(str)
  printf(" extconf failure: %s\n", str)
  exit 1
end

dir_config('iconv')
dir_config('zlib')

have_library('socket','socket')
have_library('nsl','gethostbyname')

unless have_library('m', 'atan')
  # try again for gcc 4.0
  saveflags = $CFLAGS
  $CFLAGS += ' -fno-builtin'
  unless have_library('m', 'atan')
    crash('need libm')
  end
  $CFLAGS = saveflags
end

unless have_library('z', 'inflate') or
       have_library('zlib', 'inflate') or
       have_library('zlib1', 'inflate') or
       have_library('libz', 'inflate')
  crash('need zlib')
else
  $defs.push('-DHAVE_ZLIB_H')
end

unless have_library('iconv','iconv_open') or 
       have_library('iconv','libiconv_open') or
       have_library('libiconv', 'libiconv_open') or
       have_library('libiconv', 'iconv_open') or
       have_library('c','iconv_open') or
       have_library('recode','iconv_open') or
       have_library('iconv')
  crash(<<EOL)
need libiconv.

Install the libiconv or try passing one of the following options
to extconf.rb:

  --with-iconv-dir=/path/to/iconv
  --with-iconv-lib=/path/to/iconv/lib
  --with-iconv-include=/path/to/iconv/include
EOL
end

if (xc = with_config('xml2-config')) or RUBY_PLATFORM.match(/darwin/i) then
  xc = 'xml2-config' if xc == true or xc.nil?
  cflags = `#{xc} --cflags`.chomp
  if $? != 0
		cflags = nil
	else
  	libs = `#{xc} --libs`.chomp
  	if $? != 0
			libs = nil
		else
  		$CFLAGS += ' ' + cflags
  		$libs = libs + " " + $libs
		end
	end
else
	dir_config('xml2')
end

unless (have_library('xml2', 'xmlParseDoc') or
				have_library('libxml2', 'xmlParseDoc') or
				find_library('xml2', 'xmlParseDoc', '/opt/lib', '/usr/local/lib', '/usr/lib')) and 
			 (have_header('libxml/xmlversion.h') or
			  find_header('libxml/xmlversion.h',
										'/opt/include/libxml2', 
										'/usr/local/include/libxml2',
										'/usr/include/libxml2'))
		crash(<<EOL)
need libxml2.

    Install the library or try one of the following options to extconf.rb:

      --with-xml2-config=/path/to/xml2-config
      --with-xml2-dir=/path/to/libxml2
      --with-xml2-lib=/path/to/libxml2/lib
      --with-xml2-include=/path/to/libxml2/include
EOL
end

# For FreeBSD add /usr/local/include
$INCFLAGS << " -I/usr/local/include"

$CFLAGS << ' ' << $INCFLAGS

#$INSTALLFILES = [["libxml.rb", "$(RUBYLIBDIR)", "../xml"]]

create_header()
create_makefile('libxml_ruby')
