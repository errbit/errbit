if RUBY_PLATFORM == "java"
  # Don't do anything when run in JRuby; this allows gem installation to pass.
  # We need to write a dummy Makefile so that RubyGems doesn't think compilation
  # failed.
  File.open('Makefile', 'w') do |f|
    f.puts "all:"
    f.puts "\t@true"
    f.puts "install:"
    f.puts "\t@true"
  end
  exit 0
elsif defined?(RUBY_ENGINE) && RUBY_ENGINE == "maglev"
  # Maglev doesn't support C extensions, fall back to compiling an FFI usable
  # library
  File.open('Makefile', 'w') do |f|
    f.puts <<-MAKEFILE
CFLAGS = -fPIC
OBJS = bcrypt.o blowfish.o
DLIB = bcrypt_ext.so
OS ?= $(strip $(shell uname -s | tr '[:upper:]' '[:lower:]'))
ifeq ($(OS),darwin)
	DLIB = bcrypt_ext.dylib
	CFLAGS += -dynamiclib
endif

all: $(OBJS)
	cc -shared -o $(DLIB) $(OBJS)
install:
	install $(DLIB) "../../lib/"
clean:
	$(RM) $(OBJS) bcrypt_ext.so
    MAKEFILE
  end
  exit 0
else
  require "mkmf"
  dir_config("bcrypt_ext")
  create_makefile("bcrypt_ext")
end
