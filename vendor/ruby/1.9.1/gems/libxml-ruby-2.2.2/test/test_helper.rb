# encoding: UTF-8

# To make testing/debugging easier, test within this source tree versus an installed gem

dir = File.dirname(__FILE__)
root = File.expand_path(File.join(dir, '..'))
lib = File.expand_path(File.join(root, 'lib'))
ext = File.expand_path(File.join(root, 'ext', 'libxml'))

$LOAD_PATH << lib
$LOAD_PATH << ext

require 'xml'

