# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "columnize"
  s.version = "0.3.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["R. Bernstein"]
  s.date = "2011-07-05"
  s.description = "\nIn showing a long lists, sometimes one would prefer to see the value\narranged aligned in columns. Some examples include listing methods\nof an object or debugger commands. \n\nAn Example:\n```\nrequire \"columnize\"\n  Columnize.columnize((1..100).to_a, :displaywidth=>60)\n  puts Columnize.columnize((1..100).to_a, :displaywidth=>60)\n  1   8  15  22  29  36  43  50  57  64  71  78  85  92   99\n  2   9  16  23  30  37  44  51  58  65  72  79  86  93  100\n  3  10  17  24  31  38  45  52  59  66  73  80  87  94\n  4  11  18  25  32  39  46  53  60  67  74  81  88  95\n  5  12  19  26  33  40  47  54  61  68  75  82  89  96\n  6  13  20  27  34  41  48  55  62  69  76  83  90  97\n  7  14  21  28  35  42  49  56  63  70  77  84  91  98\n\n  See Examples in the rdoc documentation for more examples.\n```\n"
  s.email = "rockyb@rubyforge.net"
  s.extra_rdoc_files = ["README", "lib/columnize.rb", "COPYING"]
  s.files = ["README", "lib/columnize.rb", "COPYING"]
  s.homepage = "https://github.com/rocky/columnize"
  s.licenses = ["Ruby", "GPL2"]
  s.rdoc_options = ["--verbose", "--main", "README", "--title", "Columnize 0.3.4 Documentation"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.2")
  s.rubyforge_project = "columnize"
  s.rubygems_version = "1.8.15"
  s.summary = "Module to format an Array as an Array of String aligned in columns"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
