require 'premailer'

Premailer.class_eval do
  protected
  # When using the 'stylesheet_link_tag' helper in Rails, css URIs are given with
  # a leading slash and a cache buster (e.g. ?12412422).
  # This override handles these cases, while falling back to the default implementation.
  def load_css_from_local_file_with_rails_path!(path)
    rails_path = Rails.root.join("public", path.sub(/\?[0-9a-zA-Z]+$/, '').sub(/^\//, '')).to_s
    if File.exist?(rails_path)
      load_css_from_string(File.read(rails_path))
    else
      load_css_from_local_file_without_rails_path!(path)
    end
  end
  alias_method_chain :load_css_from_local_file!, :rails_path

end

