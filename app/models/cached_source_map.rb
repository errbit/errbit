class CachedSourceMap
  include Mongoid::Document

  field :js_file_url, type: String
  field :data, type: Hash

  def original_line(generated_line)
    AirbrakeApi::V3::SourceMapLine.new(source_map, generated_line).original_line
  end

  private

  def source_map
    @source_map ||= SourceMap::Map.from_hash(data)
  end
end
