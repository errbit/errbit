module Term

  # The ANSIColor module can be used for namespacing and mixed into your own
  # classes.
  module ANSIColor
    require 'term/ansicolor/version'

    # :stopdoc:
    ATTRIBUTES = [
      [ :clear              ,   0 ],     # String#clear is already used to empty string in Ruby 1.9
      [ :reset              ,   0 ],     # synonym for :clear
      [ :bold               ,   1 ], 
      [ :dark               ,   2 ], 
      [ :italic             ,   3 ],     # not widely implemented
      [ :underline          ,   4 ], 
      [ :underscore         ,   4 ],     # synonym for :underline
      [ :blink              ,   5 ], 
      [ :rapid_blink        ,   6 ],     # not widely implemented
      [ :negative           ,   7 ],     # no reverse because of String#reverse
      [ :concealed          ,   8 ], 
      [ :strikethrough      ,   9 ],     # not widely implemented
      [ :black              ,  30 ], 
      [ :red                ,  31 ], 
      [ :green              ,  32 ], 
      [ :yellow             ,  33 ], 
      [ :blue               ,  34 ], 
      [ :magenta            ,  35 ], 
      [ :cyan               ,  36 ], 
      [ :white              ,  37 ], 
      [ :on_black           ,  40 ], 
      [ :on_red             ,  41 ], 
      [ :on_green           ,  42 ], 
      [ :on_yellow          ,  43 ], 
      [ :on_blue            ,  44 ], 
      [ :on_magenta         ,  45 ], 
      [ :on_cyan            ,  46 ], 
      [ :on_white           ,  47 ],
      [ :intense_black      ,  90 ],    # High intensity, aixterm (works in OS X)
      [ :intense_red        ,  91 ], 
      [ :intense_green      ,  92 ], 
      [ :intense_yellow     ,  93 ], 
      [ :intense_blue       ,  94 ], 
      [ :intense_magenta    ,  95 ], 
      [ :intense_cyan       ,  96 ], 
      [ :intense_white      ,  97 ], 
      [ :on_intense_black   , 100 ],    # High intensity background, aixterm (works in OS X)
      [ :on_intense_red     , 101 ], 
      [ :on_intense_green   , 102 ], 
      [ :on_intense_yellow  , 103 ], 
      [ :on_intense_blue    , 104 ], 
      [ :on_intense_magenta , 105 ], 
      [ :on_intense_cyan    , 106 ], 
      [ :on_intense_white   , 107 ]
    ]

    ATTRIBUTE_NAMES = ATTRIBUTES.transpose.first
    # :startdoc:

    # Returns true if Term::ANSIColor supports the +feature+.
    #
    # The feature :clear, that is mixing the clear color attribute into String,
    # is only supported on ruby implementations, that do *not* already
    # implement the String#clear method. It's better to use the reset color
    # attribute instead.
    def support?(feature)
      case feature
      when :clear
        !String.instance_methods(false).map(&:to_sym).include?(:clear)
      end
    end
    # Returns true, if the coloring function of this module
    # is switched on, false otherwise.
    def self.coloring?
      @coloring
    end

    # Turns the coloring on or off globally, so you can easily do
    # this for example:
    #  Term::ANSIColor::coloring = STDOUT.isatty
    def self.coloring=(val)
      @coloring = val
    end
    self.coloring = true

    ATTRIBUTES.each do |c, v|
      eval <<-EOT
        def #{c}(string = nil)
          result = ''
          result << "\e[#{v}m" if Term::ANSIColor.coloring?
          if block_given?
            result << yield
          elsif string.respond_to?(:to_str)
            result << string.to_str
          elsif respond_to?(:to_str)
            result << to_str
          else
            return result #only switch on
          end
          result << "\e[0m" if Term::ANSIColor.coloring?
          result
        end
      EOT
    end

    # Regular expression that is used to scan for ANSI-sequences while
    # uncoloring strings.
    COLORED_REGEXP = /\e\[(?:(?:[349]|10)[0-7]|[0-9])?m/

    # Returns an uncolored version of the string, that is all
    # ANSI-sequences are stripped from the string.
    def uncolored(string = nil) # :yields:
      if block_given?
        yield.to_str.gsub(COLORED_REGEXP, '')
      elsif string.respond_to?(:to_str)
        string.to_str.gsub(COLORED_REGEXP, '')
      elsif respond_to?(:to_str)
        to_str.gsub(COLORED_REGEXP, '')
      else
        ''
      end
    end

    module_function

    # Returns an array of all Term::ANSIColor attributes as symbols.
    def attributes
      ATTRIBUTE_NAMES
    end
    extend self
  end
end
