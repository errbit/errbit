require 'pathname'
require 'rugged'
require 'fileutils'
require 'oga'

# Walk the github refs looking for all release tags and gathering up all the
# files from the docs/ folder for each release (plus master).
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
    sort_versions
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
    if entry_path =~ /.md$/
      content = "---\n---\n" << content
      rewrite_image_hrefs(content)
      remove_target_attributes(content)
    end

    write_file_if_changed(entry_path, content)
  end

  # use local path to images rather than routing them through github sites
  def rewrite_image_hrefs(content)
    content.gsub!(%r(https?://errbit.github.com/errbit([^"]+))) do
      $1
    end
  end

  # get rid of any annoying target=_blank links
  def remove_target_attributes(content)
    content.gsub!(%r(target="_blank"), '')
  end

  # only write the file if necessary
  def write_file_if_changed(path, content)
    unless File.exist?(path) && File.read(path) == content
      puts "Writing #{path}"
      File.write(path, content)
    end
  end

  # delete whatever files we don't need
  def delete_entries(entries)
    entries.each do |path|
      puts "Deleting #{path}"
      File.delete(path)
    end
  end

  # master first, then descending numerically (by semver semantics)
  def sort_versions
    @versions.sort! do |a,b|
      if a == 'master'
        -1
      elsif b == 'master'
        1
      else
        va = a.sub(/^v/, '')
        vb = b.sub(/^v/, '')
        0 - (Gem::Version.new(va) <=> Gem::Version.new(vb))
      end
    end
  end
end
