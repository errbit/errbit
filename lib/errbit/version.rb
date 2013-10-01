module Errbit::Version
  MAJOR = 0
  MINOR = 3
  PATCH = 0

  def self.to_s
    "#{MAJOR}.#{MINOR}.#{PATCH}.dev"
  end
end
