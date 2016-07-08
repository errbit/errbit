require 'pathname'
require 'rugged'
require 'fileutils'
require 'oga'

class DocBuilder
  attr_reader :versions

  def initialize(path)
    @repo = Rugged::Repository.new(path)
    @versions = []
  end

  def run
    @repo.tags.each do |tag|
      next unless tag.name =~ /^v.+/
      build_tree(tag.target.tree, tag.name.dup)
    end

    master = @repo.branches['master']
    build_tree(master.target.tree, 'master')
  end

  def build_tree(tree, version)
    path = File.join('docs', version)
    puts "Building docs for path #{path}..."

    @versions << version

    paths_to_keep = []

    tree.walk(:preorder) do |root, entry|
      next unless root =~ /^docs\// || entry[:name] == 'README.md'
      entry_path = path_for_node(root, entry, path)
      paths_to_keep << entry_path
      handle_entry(entry, entry_path)
      # puts entry_path
    end

    delete_entries(Dir["#{path}/**/*"] - paths_to_keep)
  end

  def path_for_node(root, entry, path)
    if root.empty? && entry[:name] == 'README.md'
      File.join(path, 'index.md')
    else
      File.join(path, root.sub(/^docs\//, ''), entry[:name])
    end
  end

  def handle_entry(entry, entry_path)
    return unless entry[:type] == :blob

    dir = File.dirname(entry_path)
    FileUtils.mkdir_p(dir) unless File.exist?(dir)

    content = @repo.lookup(entry[:oid]).text

    # stuff the front of the md files with front-matter
    content = "---\n---\n" << content if entry_path =~ /\.md$/
    write_file_if_changed(entry_path, content)
  end

  def write_file_if_changed(path, content)
    if File.read(path) != content
      puts "Writing #{path}"
      File.write(path, content)
    end
  end

  def delete_entries(entries)
    entries.each do |path|
      puts "Deleting #{path}"
      File.delete(path)
    end
  end
end
