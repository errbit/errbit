# Liquid tag for rendering Rouge CSS
#
# Usage:
# {% rouge_css <theme> [mode] %}
#
# Examples:
# {% rouge_css github %}
# {% rouge_css base16 light %}
class RougeCss < Liquid::Tag
  def initialize(tag_name, args, tokens)
    super
    args_array = args.strip.split(' ')
    @theme_name = args_array.shift
    @theme_mode = args_array.shift
  end

  def render(context)
    theme = Rouge::Theme.registry[@theme_name]
    theme.mode(@theme_mode) if @theme_mode
    "<style>#{theme.render(scope: '.highlight')}</style>"
  end
end

Liquid::Template.register_tag('rouge_css', RougeCss)
