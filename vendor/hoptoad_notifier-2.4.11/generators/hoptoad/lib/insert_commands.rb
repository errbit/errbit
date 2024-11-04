# Mostly pinched from http://github.com/ryanb/nifty-generators/tree/master

Rails::Generator::Commands::Base.class_eval do
  def file_contains?(relative_destination, line)
    File.read(destination_path(relative_destination)).include?(line)
  end
end

Rails::Generator::Commands::Create.class_eval do
  def append_to(file, line)
    logger.insert "#{line} appended to #{file}"
    unless options[:pretend] || file_contains?(file, line)
      File.open(file, "a") do |file|
        file.puts
        file.puts line
      end
    end
  end
end

Rails::Generator::Commands::Destroy.class_eval do
  def append_to(file, line)
    logger.remove "#{line} removed from #{file}"
    unless options[:pretend]
      gsub_file file, "\n#{line}", ''
    end
  end
end

Rails::Generator::Commands::List.class_eval do
  def append_to(file, line)
    logger.insert "#{line} appended to #{file}"
  end
end
