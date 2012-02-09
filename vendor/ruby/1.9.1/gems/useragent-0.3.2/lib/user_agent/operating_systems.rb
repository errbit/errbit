class UserAgent
  module OperatingSystems
    Windows = {
      "Windows NT 6.1"  => "Windows 7",
      "Windows NT 6.0"  => "Windows Vista",
      "Windows NT 5.2"  => "Windows XP x64 Edition",
      "Windows NT 5.1"  => "Windows XP",
      "Windows NT 5.01" => "Windows 2000, Service Pack 1 (SP1)",
      "Windows NT 5.0"  => "Windows 2000",
      "Windows NT 4.0"  => "Windows NT 4.0",
      "Windows 98"      => "Windows 98",
      "Windows 95"      => "Windows 95",
      "Windows CE"      => "Windows CE"
    }.freeze

    def self.normalize_os(os)
      Windows[os] || os
    end
  end
end
