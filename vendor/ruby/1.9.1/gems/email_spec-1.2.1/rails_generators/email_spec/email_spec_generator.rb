# This generator adds email steps to the step definitions directory 
generator_base = defined?(Rails) ? Rails::Generator::Base : RubiGen::Base
class EmailSpecGenerator < generator_base
  def manifest
    record do |m|
      m.directory 'features/step_definitions'
      m.file      'email_steps.rb', 'features/step_definitions/email_steps.rb'
    end
  end

protected

  def banner
    "Usage: #{$0} email_spec"
  end

end
