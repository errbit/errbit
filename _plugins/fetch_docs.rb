require 'pry'
require_relative '../lib/doc_builder'
require_relative '../lib/kramdown_monkey_patches'

Jekyll::Hooks.register :site, :after_reset do |site|
  doc_builder = DocBuilder.new('.')
  doc_builder.run
  site.config['docs'] = { 'versions' => doc_builder.versions.sort }
end
