
SHELL = /bin/sh

# V=0 quiet, V=1 verbose.  other values don't work.
V = 0
Q1 = $(V:1=)
Q = $(Q1:0=@)
n=$(NULLCMD)
ECHO1 = $(V:1=@$n)
ECHO = $(ECHO1:0=@echo)

#### Start of system configuration section. ####

srcdir = .
topdir = /Users/shuky/.rvm/rubies/ruby-1.9.3-p0/include/ruby-1.9.1
hdrdir = /Users/shuky/.rvm/rubies/ruby-1.9.3-p0/include/ruby-1.9.1
arch_hdrdir = /Users/shuky/.rvm/rubies/ruby-1.9.3-p0/include/ruby-1.9.1/$(arch)
VPATH = $(srcdir):$(arch_hdrdir)/ruby:$(hdrdir)/ruby
prefix = $(DESTDIR)/Users/shuky/.rvm/rubies/ruby-1.9.3-p0
rubylibprefix = $(libdir)/$(RUBY_BASE_NAME)
exec_prefix = $(prefix)
vendorhdrdir = $(rubyhdrdir)/vendor_ruby
sitehdrdir = $(rubyhdrdir)/site_ruby
rubyhdrdir = $(includedir)/$(RUBY_BASE_NAME)-$(ruby_version)
vendordir = $(rubylibprefix)/vendor_ruby
sitedir = $(rubylibprefix)/site_ruby
ridir = $(datarootdir)/$(RI_BASE_NAME)
mandir = $(datarootdir)/man
localedir = $(datarootdir)/locale
libdir = $(exec_prefix)/lib
psdir = $(docdir)
pdfdir = $(docdir)
dvidir = $(docdir)
htmldir = $(docdir)
infodir = $(datarootdir)/info
docdir = $(datarootdir)/doc/$(PACKAGE)
oldincludedir = $(DESTDIR)/usr/include
includedir = $(prefix)/include
localstatedir = $(prefix)/var
sharedstatedir = $(prefix)/com
sysconfdir = $(prefix)/etc
datadir = $(datarootdir)
datarootdir = $(prefix)/share
libexecdir = $(exec_prefix)/libexec
sbindir = $(exec_prefix)/sbin
bindir = $(exec_prefix)/bin
rubylibdir = $(rubylibprefix)/$(ruby_version)
archdir = $(rubylibdir)/$(arch)
sitelibdir = $(sitedir)/$(ruby_version)
sitearchdir = $(sitelibdir)/$(sitearch)
vendorlibdir = $(vendordir)/$(ruby_version)
vendorarchdir = $(vendorlibdir)/$(sitearch)

NULLCMD = :

CC = /usr/bin/gcc-4.2
CXX = g++-4.2
LIBRUBY = $(LIBRUBY_SO)
LIBRUBY_A = lib$(RUBY_SO_NAME)-static.a
LIBRUBYARG_SHARED = -l$(RUBY_SO_NAME)
LIBRUBYARG_STATIC = -l$(RUBY_SO_NAME)-static
OUTFLAG = -o 
COUTFLAG = -o 

RUBY_EXTCONF_H = 
cflags   =  $(optflags) $(debugflags) $(warnflags)
optflags = -O3
debugflags = -ggdb
warnflags = -Wextra -Wno-unused-parameter -Wno-parentheses -Wno-long-long -Wno-missing-field-initializers -Wpointer-arith -Wwrite-strings -Wdeclaration-after-statement -Wshorten-64-to-32 -Wimplicit-function-declaration
CFLAGS   = -fno-common $(cflags)  -fno-common -pipe  -g -DXP_UNIX -O3 -Wall -Wcast-qual -Wwrite-strings -Wconversion -Wmissing-noreturn -Winline 
INCFLAGS = -I. -I$(arch_hdrdir) -I$(hdrdir)/ruby/backward -I$(hdrdir) -I$(srcdir)
DEFS     = 
CPPFLAGS = -DHAVE_XMLHASFEATURE -DHAVE_XMLFIRSTELEMENTCHILD -DHAVE_XMLRELAXNGSETPARSERSTRUCTUREDERRORS -DHAVE_XMLRELAXNGSETPARSERSTRUCTUREDERRORS -DHAVE_XMLRELAXNGSETVALIDSTRUCTUREDERRORS -DHAVE_XMLSCHEMASETVALIDSTRUCTUREDERRORS -DHAVE_XMLSCHEMASETPARSERSTRUCTUREDERRORS -I/usr/local/Cellar/libxslt/1.1.26/include -I/usr/local/Cellar/libxml2/2.7.8/include/libxml2 -I/opt/local/include -I/usr/local/include -I/Users/shuky/.rvm/rubies/ruby-1.9.3-p0/include -I/usr/include -I/usr/include/libxml2 -D_XOPEN_SOURCE -D_DARWIN_C_SOURCE $(DEFS) $(cppflags)
CXXFLAGS = $(CFLAGS) $(cxxflags)
ldflags  = -L. 
dldflags = -Wl,-undefined,dynamic_lookup -Wl,-multiply_defined,suppress -Wl,-flat_namespace
ARCH_FLAG = 
DLDFLAGS = $(ldflags) $(dldflags)
LDSHARED = $(CC) -dynamic -bundle
LDSHAREDXX = $(CXX) -dynamic -bundle
AR = ar
EXEEXT = 

RUBY_BASE_NAME = ruby
RUBY_INSTALL_NAME = ruby
RUBY_SO_NAME = ruby.1.9.1
arch = x86_64-darwin11.2.0
sitearch = $(arch)
ruby_version = 1.9.1
ruby = /Users/shuky/.rvm/rubies/ruby-1.9.3-p0/bin/ruby
RUBY = $(ruby)
RM = rm -f
RM_RF = $(RUBY) -run -e rm -- -rf
RMDIRS = rmdir -p
MAKEDIRS = mkdir -p
INSTALL = /usr/bin/install -c
INSTALL_PROG = $(INSTALL) -m 0755
INSTALL_DATA = $(INSTALL) -m 644
COPY = cp

#### End of system configuration section. ####

preload = 

libpath = . $(libdir) /usr/local/Cellar/libxslt/1.1.26/lib /usr/local/Cellar/libxml2/2.7.8/lib /opt/local/lib /usr/local/lib /Users/shuky/.rvm/rubies/ruby-1.9.3-p0/lib /usr/lib
LIBPATH =  -L. -L$(libdir) -L/usr/local/Cellar/libxslt/1.1.26/lib -L/usr/local/Cellar/libxml2/2.7.8/lib -L/opt/local/lib -L/usr/local/lib -L/Users/shuky/.rvm/rubies/ruby-1.9.3-p0/lib -L/usr/lib
DEFFILE = 

CLEANFILES = mkmf.log
DISTCLEANFILES = 
DISTCLEANDIRS = 

extout = 
extout_prefix = 
target_prefix = /nokogiri
LOCAL_LIBS = 
LIBS = $(LIBRUBYARG_SHARED) -lexslt -lxslt -lxml2 -liconv  -lpthread -ldl -lobjc  
SRCS = html_document.c html_element_description.c html_entity_lookup.c html_sax_parser_context.c nokogiri.c xml_attr.c xml_attribute_decl.c xml_cdata.c xml_comment.c xml_document.c xml_document_fragment.c xml_dtd.c xml_element_content.c xml_element_decl.c xml_encoding_handler.c xml_entity_decl.c xml_entity_reference.c xml_io.c xml_libxml2_hacks.c xml_namespace.c xml_node.c xml_node_set.c xml_processing_instruction.c xml_reader.c xml_relax_ng.c xml_sax_parser.c xml_sax_parser_context.c xml_sax_push_parser.c xml_schema.c xml_syntax_error.c xml_text.c xml_xpath_context.c xslt_stylesheet.c
OBJS = html_document.o html_element_description.o html_entity_lookup.o html_sax_parser_context.o nokogiri.o xml_attr.o xml_attribute_decl.o xml_cdata.o xml_comment.o xml_document.o xml_document_fragment.o xml_dtd.o xml_element_content.o xml_element_decl.o xml_encoding_handler.o xml_entity_decl.o xml_entity_reference.o xml_io.o xml_libxml2_hacks.o xml_namespace.o xml_node.o xml_node_set.o xml_processing_instruction.o xml_reader.o xml_relax_ng.o xml_sax_parser.o xml_sax_parser_context.o xml_sax_push_parser.o xml_schema.o xml_syntax_error.o xml_text.o xml_xpath_context.o xslt_stylesheet.o
TARGET = nokogiri
DLLIB = $(TARGET).bundle
EXTSTATIC = 
STATIC_LIB = 

BINDIR        = $(bindir)
RUBYCOMMONDIR = $(sitedir)$(target_prefix)
RUBYLIBDIR = /Users/shuky/private_projects/private_errbit/vendor/ruby/1.9.1/gems/nokogiri-1.5.0/lib$(target_prefix)
RUBYARCHDIR = /Users/shuky/private_projects/private_errbit/vendor/ruby/1.9.1/gems/nokogiri-1.5.0/lib$(target_prefix)
HDRDIR        = $(rubyhdrdir)/ruby$(target_prefix)
ARCHHDRDIR    = $(rubyhdrdir)/$(arch)/ruby$(target_prefix)

TARGET_SO     = $(DLLIB)
CLEANLIBS     = $(TARGET).bundle 
CLEANOBJS     = *.o  *.bak

all:    $(DLLIB)
static: $(STATIC_LIB)
.PHONY: all install static install-so install-rb
.PHONY: clean clean-so clean-rb

clean-rb-default::
clean-rb::
clean-so::
clean: clean-so clean-rb-default clean-rb
		@-$(RM) $(CLEANLIBS) $(CLEANOBJS) $(CLEANFILES)

distclean-rb-default::
distclean-rb::
distclean-so::
distclean: clean distclean-so distclean-rb-default distclean-rb
		@-$(RM) Makefile $(RUBY_EXTCONF_H) conftest.* mkmf.log
		@-$(RM) core ruby$(EXEEXT) *~ $(DISTCLEANFILES)
		@-$(RMDIRS) $(DISTCLEANDIRS) 2> /dev/null || true

realclean: distclean
install: install-so install-rb

install-so: $(RUBYARCHDIR)
install-so: $(RUBYARCHDIR)/$(DLLIB)
$(RUBYARCHDIR)/$(DLLIB): $(DLLIB)
	@-$(MAKEDIRS) $(@D)
	$(INSTALL_PROG) $(DLLIB) $(@D)
install-rb: pre-install-rb install-rb-default
install-rb-default: pre-install-rb-default
pre-install-rb: Makefile
pre-install-rb-default: Makefile
pre-install-rb-default:
	$(ECHO) installing default nokogiri libraries
$(RUBYARCHDIR):
	$(Q) $(MAKEDIRS) $@

site-install: site-install-so site-install-rb
site-install-so: install-so
site-install-rb: install-rb

.SUFFIXES: .c .m .cc .mm .cxx .cpp .C .o

.cc.o:
	$(ECHO) compiling $(<)
	$(Q) $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG)$@ -c $<

.mm.o:
	$(ECHO) compiling $(<)
	$(Q) $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG)$@ -c $<

.cxx.o:
	$(ECHO) compiling $(<)
	$(Q) $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG)$@ -c $<

.cpp.o:
	$(ECHO) compiling $(<)
	$(Q) $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG)$@ -c $<

.C.o:
	$(ECHO) compiling $(<)
	$(Q) $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG)$@ -c $<

.c.o:
	$(ECHO) compiling $(<)
	$(Q) $(CC) $(INCFLAGS) $(CPPFLAGS) $(CFLAGS) $(COUTFLAG)$@ -c $<

.m.o:
	$(ECHO) compiling $(<)
	$(Q) $(CC) $(INCFLAGS) $(CPPFLAGS) $(CFLAGS) $(COUTFLAG)$@ -c $<

$(DLLIB): $(OBJS) Makefile
	$(ECHO) linking shared-object nokogiri/$(DLLIB)
	@-$(RM) $(@)
	$(Q) $(LDSHARED) -o $@ $(OBJS) $(LIBPATH) $(DLDFLAGS) $(LOCAL_LIBS) $(LIBS)



###
html_document.o: html_document.c html_document.h nokogiri.h xml_io.h	\
  xml_document.h html_entity_lookup.h xml_node.h xml_text.h		\
  xml_cdata.h xml_attr.h xml_processing_instruction.h			\
  xml_entity_reference.h xml_document_fragment.h xml_comment.h		\
  xml_node_set.h xml_dtd.h xml_attribute_decl.h xml_element_decl.h	\
  xml_entity_decl.h xml_xpath_context.h xml_element_content.h		\
  xml_sax_parser_context.h xml_sax_parser.h xml_sax_push_parser.h	\
  xml_reader.h html_sax_parser_context.h xslt_stylesheet.h		\
  xml_syntax_error.h xml_schema.h xml_relax_ng.h			\
  html_element_description.h xml_namespace.h xml_encoding_handler.h

html_element_description.o: html_element_description.c			\
 html_element_description.h nokogiri.h xml_io.h xml_document.h		\
 html_entity_lookup.h html_document.h xml_node.h xml_text.h		\
 xml_cdata.h xml_attr.h xml_processing_instruction.h			\
 xml_entity_reference.h xml_document_fragment.h xml_comment.h		\
 xml_node_set.h xml_dtd.h xml_attribute_decl.h xml_element_decl.h	\
 xml_entity_decl.h xml_xpath_context.h xml_element_content.h		\
 xml_sax_parser_context.h xml_sax_parser.h xml_sax_push_parser.h	\
 xml_reader.h html_sax_parser_context.h xslt_stylesheet.h		\
 xml_syntax_error.h xml_schema.h xml_relax_ng.h xml_namespace.h		\
 xml_encoding_handler.h

html_entity_lookup.o: html_entity_lookup.c html_entity_lookup.h		\
  nokogiri.h xml_io.h xml_document.h html_document.h xml_node.h		\
  xml_text.h xml_cdata.h xml_attr.h xml_processing_instruction.h	\
  xml_entity_reference.h xml_document_fragment.h xml_comment.h		\
  xml_node_set.h xml_dtd.h xml_attribute_decl.h xml_element_decl.h	\
  xml_entity_decl.h xml_xpath_context.h xml_element_content.h		\
  xml_sax_parser_context.h xml_sax_parser.h xml_sax_push_parser.h	\
  xml_reader.h html_sax_parser_context.h xslt_stylesheet.h		\
  xml_syntax_error.h xml_schema.h xml_relax_ng.h			\
  html_element_description.h xml_namespace.h xml_encoding_handler.h

html_sax_parser_context.o: html_sax_parser_context.c			\
 html_sax_parser_context.h nokogiri.h xml_io.h xml_document.h		\
 html_entity_lookup.h html_document.h xml_node.h xml_text.h		\
 xml_cdata.h xml_attr.h xml_processing_instruction.h			\
 xml_entity_reference.h xml_document_fragment.h xml_comment.h		\
 xml_node_set.h xml_dtd.h xml_attribute_decl.h xml_element_decl.h	\
 xml_entity_decl.h xml_xpath_context.h xml_element_content.h		\
 xml_sax_parser_context.h xml_sax_parser.h xml_sax_push_parser.h	\
 xml_reader.h xslt_stylesheet.h xml_syntax_error.h xml_schema.h		\
 xml_relax_ng.h html_element_description.h xml_namespace.h		\
 xml_encoding_handler.h

nokogiri.o: nokogiri.c nokogiri.h xml_io.h xml_document.h		\
  html_entity_lookup.h html_document.h xml_node.h xml_text.h		\
  xml_cdata.h xml_attr.h xml_processing_instruction.h			\
  xml_entity_reference.h xml_document_fragment.h xml_comment.h		\
  xml_node_set.h xml_dtd.h xml_attribute_decl.h xml_element_decl.h	\
  xml_entity_decl.h xml_xpath_context.h xml_element_content.h		\
  xml_sax_parser_context.h xml_sax_parser.h xml_sax_push_parser.h	\
  xml_reader.h html_sax_parser_context.h xslt_stylesheet.h		\
  xml_syntax_error.h xml_schema.h xml_relax_ng.h			\
  html_element_description.h xml_namespace.h xml_encoding_handler.h

xml_attr.o: xml_attr.c xml_attr.h nokogiri.h xml_io.h xml_document.h	\
  html_entity_lookup.h html_document.h xml_node.h xml_text.h		\
  xml_cdata.h xml_processing_instruction.h xml_entity_reference.h	\
  xml_document_fragment.h xml_comment.h xml_node_set.h xml_dtd.h	\
  xml_attribute_decl.h xml_element_decl.h xml_entity_decl.h		\
  xml_xpath_context.h xml_element_content.h xml_sax_parser_context.h	\
  xml_sax_parser.h xml_sax_push_parser.h xml_reader.h			\
  html_sax_parser_context.h xslt_stylesheet.h xml_syntax_error.h	\
  xml_schema.h xml_relax_ng.h html_element_description.h		\
  xml_namespace.h xml_encoding_handler.h

xml_attribute_decl.o: xml_attribute_decl.c xml_attribute_decl.h		\
  nokogiri.h xml_io.h xml_document.h html_entity_lookup.h		\
  html_document.h xml_node.h xml_text.h xml_cdata.h xml_attr.h		\
  xml_processing_instruction.h xml_entity_reference.h			\
  xml_document_fragment.h xml_comment.h xml_node_set.h xml_dtd.h	\
  xml_element_decl.h xml_entity_decl.h xml_xpath_context.h		\
  xml_element_content.h xml_sax_parser_context.h xml_sax_parser.h	\
  xml_sax_push_parser.h xml_reader.h html_sax_parser_context.h		\
  xslt_stylesheet.h xml_syntax_error.h xml_schema.h xml_relax_ng.h	\
  html_element_description.h xml_namespace.h xml_encoding_handler.h

xml_cdata.o: xml_cdata.c xml_cdata.h nokogiri.h xml_io.h		\
  xml_document.h html_entity_lookup.h html_document.h xml_node.h	\
  xml_text.h xml_attr.h xml_processing_instruction.h			\
  xml_entity_reference.h xml_document_fragment.h xml_comment.h		\
  xml_node_set.h xml_dtd.h xml_attribute_decl.h xml_element_decl.h	\
  xml_entity_decl.h xml_xpath_context.h xml_element_content.h		\
  xml_sax_parser_context.h xml_sax_parser.h xml_sax_push_parser.h	\
  xml_reader.h html_sax_parser_context.h xslt_stylesheet.h		\
  xml_syntax_error.h xml_schema.h xml_relax_ng.h			\
  html_element_description.h xml_namespace.h xml_encoding_handler.h

xml_comment.o: xml_comment.c xml_comment.h nokogiri.h xml_io.h		\
  xml_document.h html_entity_lookup.h html_document.h xml_node.h	\
  xml_text.h xml_cdata.h xml_attr.h xml_processing_instruction.h	\
  xml_entity_reference.h xml_document_fragment.h xml_node_set.h		\
  xml_dtd.h xml_attribute_decl.h xml_element_decl.h xml_entity_decl.h	\
  xml_xpath_context.h xml_element_content.h xml_sax_parser_context.h	\
  xml_sax_parser.h xml_sax_push_parser.h xml_reader.h			\
  html_sax_parser_context.h xslt_stylesheet.h xml_syntax_error.h	\
  xml_schema.h xml_relax_ng.h html_element_description.h		\
  xml_namespace.h xml_encoding_handler.h

xml_document.o: xml_document.c xml_document.h nokogiri.h xml_io.h	\
  html_entity_lookup.h html_document.h xml_node.h xml_text.h		\
  xml_cdata.h xml_attr.h xml_processing_instruction.h			\
  xml_entity_reference.h xml_document_fragment.h xml_comment.h		\
  xml_node_set.h xml_dtd.h xml_attribute_decl.h xml_element_decl.h	\
  xml_entity_decl.h xml_xpath_context.h xml_element_content.h		\
  xml_sax_parser_context.h xml_sax_parser.h xml_sax_push_parser.h	\
  xml_reader.h html_sax_parser_context.h xslt_stylesheet.h		\
  xml_syntax_error.h xml_schema.h xml_relax_ng.h			\
  html_element_description.h xml_namespace.h xml_encoding_handler.h

xml_document_fragment.o: xml_document_fragment.c			\
  xml_document_fragment.h nokogiri.h xml_io.h xml_document.h		\
  html_entity_lookup.h html_document.h xml_node.h xml_text.h		\
  xml_cdata.h xml_attr.h xml_processing_instruction.h			\
  xml_entity_reference.h xml_comment.h xml_node_set.h xml_dtd.h		\
  xml_attribute_decl.h xml_element_decl.h xml_entity_decl.h		\
  xml_xpath_context.h xml_element_content.h xml_sax_parser_context.h	\
  xml_sax_parser.h xml_sax_push_parser.h xml_reader.h			\
  html_sax_parser_context.h xslt_stylesheet.h xml_syntax_error.h	\
  xml_schema.h xml_relax_ng.h html_element_description.h		\
  xml_namespace.h xml_encoding_handler.h

xml_dtd.o: xml_dtd.c xml_dtd.h nokogiri.h xml_io.h xml_document.h	\
  html_entity_lookup.h html_document.h xml_node.h xml_text.h		\
  xml_cdata.h xml_attr.h xml_processing_instruction.h			\
  xml_entity_reference.h xml_document_fragment.h xml_comment.h		\
  xml_node_set.h xml_attribute_decl.h xml_element_decl.h		\
  xml_entity_decl.h xml_xpath_context.h xml_element_content.h		\
  xml_sax_parser_context.h xml_sax_parser.h xml_sax_push_parser.h	\
  xml_reader.h html_sax_parser_context.h xslt_stylesheet.h		\
  xml_syntax_error.h xml_schema.h xml_relax_ng.h			\
  html_element_description.h xml_namespace.h xml_encoding_handler.h

xml_element_content.o: xml_element_content.c xml_element_content.h	\
  nokogiri.h xml_io.h xml_document.h html_entity_lookup.h		\
  html_document.h xml_node.h xml_text.h xml_cdata.h xml_attr.h		\
  xml_processing_instruction.h xml_entity_reference.h			\
  xml_document_fragment.h xml_comment.h xml_node_set.h xml_dtd.h	\
  xml_attribute_decl.h xml_element_decl.h xml_entity_decl.h		\
  xml_xpath_context.h xml_sax_parser_context.h xml_sax_parser.h		\
  xml_sax_push_parser.h xml_reader.h html_sax_parser_context.h		\
  xslt_stylesheet.h xml_syntax_error.h xml_schema.h xml_relax_ng.h	\
  html_element_description.h xml_namespace.h xml_encoding_handler.h

xml_element_decl.o: xml_element_decl.c xml_element_decl.h nokogiri.h	\
  xml_io.h xml_document.h html_entity_lookup.h html_document.h		\
  xml_node.h xml_text.h xml_cdata.h xml_attr.h				\
  xml_processing_instruction.h xml_entity_reference.h			\
  xml_document_fragment.h xml_comment.h xml_node_set.h xml_dtd.h	\
  xml_attribute_decl.h xml_entity_decl.h xml_xpath_context.h		\
  xml_element_content.h xml_sax_parser_context.h xml_sax_parser.h	\
  xml_sax_push_parser.h xml_reader.h html_sax_parser_context.h		\
  xslt_stylesheet.h xml_syntax_error.h xml_schema.h xml_relax_ng.h	\
  html_element_description.h xml_namespace.h xml_encoding_handler.h

xml_encoding_handler.o: xml_encoding_handler.c xml_encoding_handler.h	\
  nokogiri.h xml_io.h xml_document.h html_entity_lookup.h		\
  html_document.h xml_node.h xml_text.h xml_cdata.h xml_attr.h		\
  xml_processing_instruction.h xml_entity_reference.h			\
  xml_document_fragment.h xml_comment.h xml_node_set.h xml_dtd.h	\
  xml_attribute_decl.h xml_element_decl.h xml_entity_decl.h		\
  xml_xpath_context.h xml_element_content.h xml_sax_parser_context.h	\
  xml_sax_parser.h xml_sax_push_parser.h xml_reader.h			\
  html_sax_parser_context.h xslt_stylesheet.h xml_syntax_error.h	\
  xml_schema.h xml_relax_ng.h html_element_description.h		\
  xml_namespace.h

xml_entity_decl.o: xml_entity_decl.c xml_entity_decl.h nokogiri.h	\
  xml_io.h xml_document.h html_entity_lookup.h html_document.h		\
  xml_node.h xml_text.h xml_cdata.h xml_attr.h				\
  xml_processing_instruction.h xml_entity_reference.h			\
  xml_document_fragment.h xml_comment.h xml_node_set.h xml_dtd.h	\
  xml_attribute_decl.h xml_element_decl.h xml_xpath_context.h		\
  xml_element_content.h xml_sax_parser_context.h xml_sax_parser.h	\
  xml_sax_push_parser.h xml_reader.h html_sax_parser_context.h		\
  xslt_stylesheet.h xml_syntax_error.h xml_schema.h xml_relax_ng.h	\
  html_element_description.h xml_namespace.h xml_encoding_handler.h

xml_entity_reference.o: xml_entity_reference.c xml_entity_reference.h	\
  nokogiri.h xml_io.h xml_document.h html_entity_lookup.h		\
  html_document.h xml_node.h xml_text.h xml_cdata.h xml_attr.h		\
  xml_processing_instruction.h xml_document_fragment.h xml_comment.h	\
  xml_node_set.h xml_dtd.h xml_attribute_decl.h xml_element_decl.h	\
  xml_entity_decl.h xml_xpath_context.h xml_element_content.h		\
  xml_sax_parser_context.h xml_sax_parser.h xml_sax_push_parser.h	\
  xml_reader.h html_sax_parser_context.h xslt_stylesheet.h		\
  xml_syntax_error.h xml_schema.h xml_relax_ng.h			\
  html_element_description.h xml_namespace.h xml_encoding_handler.h

xml_io.o: xml_io.c xml_io.h nokogiri.h xml_document.h			\
  html_entity_lookup.h html_document.h xml_node.h xml_text.h		\
  xml_cdata.h xml_attr.h xml_processing_instruction.h			\
  xml_entity_reference.h xml_document_fragment.h xml_comment.h		\
  xml_node_set.h xml_dtd.h xml_attribute_decl.h xml_element_decl.h	\
  xml_entity_decl.h xml_xpath_context.h xml_element_content.h		\
  xml_sax_parser_context.h xml_sax_parser.h xml_sax_push_parser.h	\
  xml_reader.h html_sax_parser_context.h xslt_stylesheet.h		\
  xml_syntax_error.h xml_schema.h xml_relax_ng.h			\
  html_element_description.h xml_namespace.h xml_encoding_handler.h

xml_namespace.o: xml_namespace.c xml_namespace.h nokogiri.h xml_io.h	\
  xml_document.h html_entity_lookup.h html_document.h xml_node.h	\
  xml_text.h xml_cdata.h xml_attr.h xml_processing_instruction.h	\
  xml_entity_reference.h xml_document_fragment.h xml_comment.h		\
  xml_node_set.h xml_dtd.h xml_attribute_decl.h xml_element_decl.h	\
  xml_entity_decl.h xml_xpath_context.h xml_element_content.h		\
  xml_sax_parser_context.h xml_sax_parser.h xml_sax_push_parser.h	\
  xml_reader.h html_sax_parser_context.h xslt_stylesheet.h		\
  xml_syntax_error.h xml_schema.h xml_relax_ng.h			\
  html_element_description.h xml_encoding_handler.h

xml_node.o: xml_node.c xml_node.h nokogiri.h xml_io.h xml_document.h	\
  html_entity_lookup.h html_document.h xml_text.h xml_cdata.h		\
  xml_attr.h xml_processing_instruction.h xml_entity_reference.h	\
  xml_document_fragment.h xml_comment.h xml_node_set.h xml_dtd.h	\
  xml_attribute_decl.h xml_element_decl.h xml_entity_decl.h		\
  xml_xpath_context.h xml_element_content.h xml_sax_parser_context.h	\
  xml_sax_parser.h xml_sax_push_parser.h xml_reader.h			\
  html_sax_parser_context.h xslt_stylesheet.h xml_syntax_error.h	\
  xml_schema.h xml_relax_ng.h html_element_description.h		\
  xml_namespace.h xml_encoding_handler.h

xml_node_set.o: xml_node_set.c xml_node_set.h nokogiri.h xml_io.h	\
  xml_document.h html_entity_lookup.h html_document.h xml_node.h	\
  xml_text.h xml_cdata.h xml_attr.h xml_processing_instruction.h	\
  xml_entity_reference.h xml_document_fragment.h xml_comment.h		\
  xml_dtd.h xml_attribute_decl.h xml_element_decl.h xml_entity_decl.h	\
  xml_xpath_context.h xml_element_content.h xml_sax_parser_context.h	\
  xml_sax_parser.h xml_sax_push_parser.h xml_reader.h			\
  html_sax_parser_context.h xslt_stylesheet.h xml_syntax_error.h	\
  xml_schema.h xml_relax_ng.h html_element_description.h		\
  xml_namespace.h xml_encoding_handler.h

xml_processing_instruction.o: xml_processing_instruction.c		\
 xml_processing_instruction.h nokogiri.h xml_io.h xml_document.h	\
 html_entity_lookup.h html_document.h xml_node.h xml_text.h		\
 xml_cdata.h xml_attr.h xml_entity_reference.h xml_document_fragment.h	\
 xml_comment.h xml_node_set.h xml_dtd.h xml_attribute_decl.h		\
 xml_element_decl.h xml_entity_decl.h xml_xpath_context.h		\
 xml_element_content.h xml_sax_parser_context.h xml_sax_parser.h	\
 xml_sax_push_parser.h xml_reader.h html_sax_parser_context.h		\
 xslt_stylesheet.h xml_syntax_error.h xml_schema.h xml_relax_ng.h	\
 html_element_description.h xml_namespace.h xml_encoding_handler.h

xml_reader.o: xml_reader.c xml_reader.h nokogiri.h xml_io.h		\
  xml_document.h html_entity_lookup.h html_document.h xml_node.h	\
  xml_text.h xml_cdata.h xml_attr.h xml_processing_instruction.h	\
  xml_entity_reference.h xml_document_fragment.h xml_comment.h		\
  xml_node_set.h xml_dtd.h xml_attribute_decl.h xml_element_decl.h	\
  xml_entity_decl.h xml_xpath_context.h xml_element_content.h		\
  xml_sax_parser_context.h xml_sax_parser.h xml_sax_push_parser.h	\
  html_sax_parser_context.h xslt_stylesheet.h xml_syntax_error.h	\
  xml_schema.h xml_relax_ng.h html_element_description.h		\
  xml_namespace.h xml_encoding_handler.h

xml_relax_ng.o: xml_relax_ng.c xml_relax_ng.h nokogiri.h xml_io.h	\
  xml_document.h html_entity_lookup.h html_document.h xml_node.h	\
  xml_text.h xml_cdata.h xml_attr.h xml_processing_instruction.h	\
  xml_entity_reference.h xml_document_fragment.h xml_comment.h		\
  xml_node_set.h xml_dtd.h xml_attribute_decl.h xml_element_decl.h	\
  xml_entity_decl.h xml_xpath_context.h xml_element_content.h		\
  xml_sax_parser_context.h xml_sax_parser.h xml_sax_push_parser.h	\
  xml_reader.h html_sax_parser_context.h xslt_stylesheet.h		\
  xml_syntax_error.h xml_schema.h html_element_description.h		\
  xml_namespace.h xml_encoding_handler.h

xml_sax_parser.o: xml_sax_parser.c xml_sax_parser.h nokogiri.h		\
  xml_io.h xml_document.h html_entity_lookup.h html_document.h		\
  xml_node.h xml_text.h xml_cdata.h xml_attr.h				\
  xml_processing_instruction.h xml_entity_reference.h			\
  xml_document_fragment.h xml_comment.h xml_node_set.h xml_dtd.h	\
  xml_attribute_decl.h xml_element_decl.h xml_entity_decl.h		\
  xml_xpath_context.h xml_element_content.h xml_sax_parser_context.h	\
  xml_sax_push_parser.h xml_reader.h html_sax_parser_context.h		\
  xslt_stylesheet.h xml_syntax_error.h xml_schema.h xml_relax_ng.h	\
  html_element_description.h xml_namespace.h xml_encoding_handler.h

xml_sax_parser_context.o: xml_sax_parser_context.c			\
 xml_sax_parser_context.h nokogiri.h xml_io.h xml_document.h		\
 html_entity_lookup.h html_document.h xml_node.h xml_text.h		\
 xml_cdata.h xml_attr.h xml_processing_instruction.h			\
 xml_entity_reference.h xml_document_fragment.h xml_comment.h		\
 xml_node_set.h xml_dtd.h xml_attribute_decl.h xml_element_decl.h	\
 xml_entity_decl.h xml_xpath_context.h xml_element_content.h		\
 xml_sax_parser.h xml_sax_push_parser.h xml_reader.h			\
 html_sax_parser_context.h xslt_stylesheet.h xml_syntax_error.h		\
 xml_schema.h xml_relax_ng.h html_element_description.h			\
 xml_namespace.h xml_encoding_handler.h

xml_sax_push_parser.o: xml_sax_push_parser.c xml_sax_push_parser.h	\
  nokogiri.h xml_io.h xml_document.h html_entity_lookup.h		\
  html_document.h xml_node.h xml_text.h xml_cdata.h xml_attr.h		\
  xml_processing_instruction.h xml_entity_reference.h			\
  xml_document_fragment.h xml_comment.h xml_node_set.h xml_dtd.h	\
  xml_attribute_decl.h xml_element_decl.h xml_entity_decl.h		\
  xml_xpath_context.h xml_element_content.h xml_sax_parser_context.h	\
  xml_sax_parser.h xml_reader.h html_sax_parser_context.h		\
  xslt_stylesheet.h xml_syntax_error.h xml_schema.h xml_relax_ng.h	\
  html_element_description.h xml_namespace.h xml_encoding_handler.h

xml_schema.o: xml_schema.c xml_schema.h nokogiri.h xml_io.h		\
  xml_document.h html_entity_lookup.h html_document.h xml_node.h	\
  xml_text.h xml_cdata.h xml_attr.h xml_processing_instruction.h	\
  xml_entity_reference.h xml_document_fragment.h xml_comment.h		\
  xml_node_set.h xml_dtd.h xml_attribute_decl.h xml_element_decl.h	\
  xml_entity_decl.h xml_xpath_context.h xml_element_content.h		\
  xml_sax_parser_context.h xml_sax_parser.h xml_sax_push_parser.h	\
  xml_reader.h html_sax_parser_context.h xslt_stylesheet.h		\
  xml_syntax_error.h xml_relax_ng.h html_element_description.h		\
  xml_namespace.h xml_encoding_handler.h

xml_syntax_error.o: xml_syntax_error.c xml_syntax_error.h nokogiri.h	\
  xml_io.h xml_document.h html_entity_lookup.h html_document.h		\
  xml_node.h xml_text.h xml_cdata.h xml_attr.h				\
  xml_processing_instruction.h xml_entity_reference.h			\
  xml_document_fragment.h xml_comment.h xml_node_set.h xml_dtd.h	\
  xml_attribute_decl.h xml_element_decl.h xml_entity_decl.h		\
  xml_xpath_context.h xml_element_content.h xml_sax_parser_context.h	\
  xml_sax_parser.h xml_sax_push_parser.h xml_reader.h			\
  html_sax_parser_context.h xslt_stylesheet.h xml_schema.h		\
  xml_relax_ng.h html_element_description.h xml_namespace.h		\
  xml_encoding_handler.h

xml_text.o: xml_text.c xml_text.h nokogiri.h xml_io.h xml_document.h	\
  html_entity_lookup.h html_document.h xml_node.h xml_cdata.h		\
  xml_attr.h xml_processing_instruction.h xml_entity_reference.h	\
  xml_document_fragment.h xml_comment.h xml_node_set.h xml_dtd.h	\
  xml_attribute_decl.h xml_element_decl.h xml_entity_decl.h		\
  xml_xpath_context.h xml_element_content.h xml_sax_parser_context.h	\
  xml_sax_parser.h xml_sax_push_parser.h xml_reader.h			\
  html_sax_parser_context.h xslt_stylesheet.h xml_syntax_error.h	\
  xml_schema.h xml_relax_ng.h html_element_description.h		\
  xml_namespace.h xml_encoding_handler.h

xml_xpath_context.o: xml_xpath_context.c xml_xpath_context.h		\
  nokogiri.h xml_io.h xml_document.h html_entity_lookup.h		\
  html_document.h xml_node.h xml_text.h xml_cdata.h xml_attr.h		\
  xml_processing_instruction.h xml_entity_reference.h			\
  xml_document_fragment.h xml_comment.h xml_node_set.h xml_dtd.h	\
  xml_attribute_decl.h xml_element_decl.h xml_entity_decl.h		\
  xml_element_content.h xml_sax_parser_context.h xml_sax_parser.h	\
  xml_sax_push_parser.h xml_reader.h html_sax_parser_context.h		\
  xslt_stylesheet.h xml_syntax_error.h xml_schema.h xml_relax_ng.h	\
  html_element_description.h xml_namespace.h xml_encoding_handler.h

xslt_stylesheet.o: xslt_stylesheet.c xslt_stylesheet.h nokogiri.h	\
  xml_io.h xml_document.h html_entity_lookup.h html_document.h		\
  xml_node.h xml_text.h xml_cdata.h xml_attr.h				\
  xml_processing_instruction.h xml_entity_reference.h			\
  xml_document_fragment.h xml_comment.h xml_node_set.h xml_dtd.h	\
  xml_attribute_decl.h xml_element_decl.h xml_entity_decl.h		\
  xml_xpath_context.h xml_element_content.h xml_sax_parser_context.h	\
  xml_sax_parser.h xml_sax_push_parser.h xml_reader.h			\
  html_sax_parser_context.h xml_syntax_error.h xml_schema.h		\
  xml_relax_ng.h html_element_description.h xml_namespace.h		\
  xml_encoding_handler.h
