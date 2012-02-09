module CssParser


  def self.regex_possible_values *values
    Regexp.new("([\s]*^)?(#{values.join('|')})([\s]*$)?", 'i')
  end

  # :stopdoc:
  # Base types
  RE_NL = Regexp.new('(\n|\r\n|\r|\f)')
  RE_NON_ASCII = Regexp.new('([\x00-\xFF])', Regexp::IGNORECASE, 'n')  #[^\0-\177]
  RE_UNICODE = Regexp.new('(\\\\[0-9a-f]{1,6}(\r\n|[ \n\r\t\f])*)', Regexp::IGNORECASE | Regexp::EXTENDED | Regexp::MULTILINE, 'n')
  RE_ESCAPE = Regexp.union(RE_UNICODE, '|(\\\\[^\n\r\f0-9a-f])')
  RE_IDENT = Regexp.new("[\-]?([_a-z]|#{RE_NON_ASCII}|#{RE_ESCAPE})([_a-z0-9\-]|#{RE_NON_ASCII}|#{RE_ESCAPE})*", Regexp::IGNORECASE, 'n')

  # General strings
  RE_STRING1 = Regexp.new('(\"(.[^\n\r\f\\"]*|\\\\' + RE_NL.to_s + '|' + RE_ESCAPE.to_s + ')*\")')
  RE_STRING2 = Regexp.new('(\'(.[^\n\r\f\\\']*|\\\\' + RE_NL.to_s + '|' + RE_ESCAPE.to_s + ')*\')')
  RE_STRING = Regexp.union(RE_STRING1, RE_STRING2)

  RE_INHERIT = regex_possible_values 'inherit'

  RE_URI = Regexp.new('(url\([\s]*([\s]*' + RE_STRING.to_s + '[\s]*)[\s]*\))|(url\([\s]*([!#$%&*\-~]|' + RE_NON_ASCII.to_s + '|' + RE_ESCAPE.to_s + ')*[\s]*)\)', Regexp::IGNORECASE | Regexp::EXTENDED  | Regexp::MULTILINE, 'n')
  URI_RX = /url\(("([^"]*)"|'([^']*)'|([^)]*))\)/im

  # Initial parsing
  RE_AT_IMPORT_RULE = /\@import[\s]+(url\()?["''"]?(.[^'"\s"']*)["''"]?\)?([\w\s\,^\])]*)\)?;?/
  
  #--
  #RE_AT_MEDIA_RULE = Regexp.new('(\"(.[^\n\r\f\\"]*|\\\\' + RE_NL.to_s + '|' + RE_ESCAPE.to_s + ')*\")')
  
  #RE_AT_IMPORT_RULE = Regexp.new('@import[\s]*(' + RE_STRING.to_s + ')([\w\s\,]*)[;]?', Regexp::IGNORECASE) -- should handle url() even though it is not allowed
  #++
  IMPORTANT_IN_PROPERTY_RX = /[\s]*!important[\s]*/i

  RE_INSIDE_OUTSIDE = regex_possible_values 'inside', 'outside'
  RE_SCROLL_FIXED = regex_possible_values 'scroll', 'fixed'
  RE_REPEAT = regex_possible_values 'repeat(\-x|\-y)*|no\-repeat'
  RE_LIST_STYLE_TYPE = regex_possible_values 'disc', 'circle', 'square', 'decimal-leading-zero', 'decimal', 'lower-roman',
                                             'upper-roman', 'lower-greek', 'lower-alpha', 'lower-latin', 'upper-alpha',
                                             'upper-latin', 'hebrew', 'armenian', 'georgian', 'cjk-ideographic', 'hiragana',
                                             'hira-gana-iroha', 'katakana-iroha', 'katakana', 'none'

  STRIP_CSS_COMMENTS_RX = /\/\*.*?\*\//m
  STRIP_HTML_COMMENTS_RX = /\<\!\-\-|\-\-\>/m

  # Special units
  BOX_MODEL_UNITS_RX = /(auto|inherit|0|([\-]*([0-9]+|[0-9]*\.[0-9]+)(e[mx]+|px|[cm]+m|p[tc+]|in|\%)))([\s;]|\Z)/imx
  RE_LENGTH_OR_PERCENTAGE = Regexp.new('([\-]*(([0-9]*\.[0-9]+)|[0-9]+)(e[mx]+|px|[cm]+m|p[tc+]|in|\%))', Regexp::IGNORECASE)
  RE_BACKGROUND_POSITION = Regexp.new("((((#{RE_LENGTH_OR_PERCENTAGE})|left|center|right|top|bottom)[\s]*){1,2})", Regexp::IGNORECASE | Regexp::EXTENDED)
  FONT_UNITS_RX = /(([x]+\-)*small|medium|large[r]*|auto|inherit|([0-9]+|[0-9]*\.[0-9]+)(e[mx]+|px|[cm]+m|p[tc+]|in|\%)*)/i
  RE_BORDER_STYLE = /([\s]*^)?(none|hidden|dotted|dashed|solid|double|dot-dash|dot-dot-dash|wave|groove|ridge|inset|outset)([\s]*$)?/imx
  RE_BORDER_UNITS = Regexp.union(BOX_MODEL_UNITS_RX, /(thin|medium|thick)/i)
  
 
  # Patterns for specificity calculations
  NON_ID_ATTRIBUTES_AND_PSEUDO_CLASSES_RX= /
    (\.[\w]+)                     # classes
    |
    \[(\w+)                       # attributes
    |
    (\:(                          # pseudo classes
      link|visited|active
      |hover|focus
      |lang
      |target
      |enabled|disabled|checked|indeterminate
      |root
      |nth-child|nth-last-child|nth-of-type|nth-last-of-type
      |first-child|last-child|first-of-type|last-of-type
      |only-child|only-of-type
      |empty|contains
    ))
  /ix
  ELEMENTS_AND_PSEUDO_ELEMENTS_RX = /
    ((^|[\s\+\>\~]+)[\w]+       # elements
    |                   
    \:{1,2}(                    # pseudo-elements
      after|before
      |first-letter|first-line
      |selection
    )
  )/ix

  # Colours
  RE_COLOUR_NUMERIC = Regexp.new('((hsl|rgb)[\s]*\([\s-]*[\d]+(\.[\d]+)?[%\s]*,[\s-]*[\d]+(\.[\d]+)?[%\s]*,[\s-]*[\d]+(\.[\d]+)?[%\s]*\))', Regexp::IGNORECASE)
  RE_COLOUR_NUMERIC_ALPHA = Regexp.new('((hsla|rgba)[\s]*\([\s-]*[\d]+(\.[\d]+)?[%\s]*,[\s-]*[\d]+(\.[\d]+)?[%\s]*,[\s-]*[\d]+(\.[\d]+)?[%\s]*,[\s-]*[\d]+(\.[\d]+)?[%\s]*\))', Regexp::IGNORECASE)
  RE_COLOUR_HEX = /(#([0-9a-f]{6}|[0-9a-f]{3})([\s;]|$))/i
  RE_COLOUR_NAMED = /([\s]*^)?(aqua|black|blue|fuchsia|gray|green|lime|maroon|navy|olive|orange|purple|red|silver|teal|white|yellow|transparent)([\s]*$)?/i
  RE_COLOUR = Regexp.union(RE_COLOUR_NUMERIC, RE_COLOUR_NUMERIC_ALPHA, RE_COLOUR_HEX, RE_COLOUR_NAMED)
  # :startdoc:
end
