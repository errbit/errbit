# A sample Guardfile
# More info at https://github.com/guard/guard#readme

# rubies = %w[
#   1.8.6
#   1.8.7
#   1.9.2
#   ree
#   jruby
# ].map { |ruby| "#{ruby}@webmock" }

rspec_options = {
  # :rvm          => rubies,
  :all_on_start => false,
  :notification => false,
  :cli          => '--color',
  :version      => 2
}

guard 'rspec', rspec_options do
  watch(%r{^spec/.+_spec\.rb})
  watch(%r{^lib/(.+)\.rb})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb') { "spec" }
end
