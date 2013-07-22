module Errbit::Version
  MAJOR = 0
  MINOR = 1
  PATCH = 0

  def self.to_s
    "#{MAJOR}.#{MINOR}.#{PATCH}"
  end
end
