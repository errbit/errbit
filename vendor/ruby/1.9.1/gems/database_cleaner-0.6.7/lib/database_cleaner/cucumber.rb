Before do
  DatabaseCleaner.start
end

After do
  begin
    DatabaseCleaner.clean
  rescue Exception =>  e
    DatabaseCleaner.logger.error "Exception encountered by DatabaseCleaner in Cucumber After block: #{e}"
  end
end
