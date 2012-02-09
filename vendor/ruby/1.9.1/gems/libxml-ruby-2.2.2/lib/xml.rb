# encoding: UTF-8

# This file loads libxml and adds the LibXML namespace
# to the toplevel for conveneience. The end result
# is to have XML:: universally exposed.
#
# It is recommend that you only load this file for libs
# that do not have their own namespace, eg. administrative
# scripts, personal programs, etc. For other applications
# require 'libxml' instead and include LibXML into your 
# app/libs namespace.

require 'libxml'
include LibXML