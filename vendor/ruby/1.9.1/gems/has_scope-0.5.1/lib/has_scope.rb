module HasScope
  TRUE_VALUES = ["true", true, "1", 1]

  ALLOWED_TYPES = {
    :array   => [ Array ],
    :hash    => [ Hash ],
    :boolean => [ Object ],
    :default => [ String, Numeric ]
  }

  def self.included(base)
    base.class_eval do
      extend ClassMethods
      helper_method :current_scopes
      class_attribute :scopes_configuration, :instance_writer => false
    end
  end

  module ClassMethods
    # Detects params from url and apply as scopes to your classes.
    #
    # == Options
    #
    # * <tt>:type</tt> - Checks the type of the parameter sent. If set to :boolean
    #                    it just calls the named scope, without any argument. By default,
    #                    it does not allow hashes or arrays to be given, except if type
    #                    :hash or :array are set.
    #
    # * <tt>:only</tt> - In which actions the scope is applied. By default is :all.
    #
    # * <tt>:except</tt> - In which actions the scope is not applied. By default is :none.
    #
    # * <tt>:as</tt> - The key in the params hash expected to find the scope.
    #                  Defaults to the scope name.
    #
    # * <tt>:using</tt> - If type is a hash, you can provide :using to convert the hash to
    #                     a named scope call with several arguments.
    #
    # * <tt>:if</tt> - Specifies a method, proc or string to call to determine
    #                  if the scope should apply
    #
    # * <tt>:unless</tt> - Specifies a method, proc or string to call to determine
    #                      if the scope should NOT apply.
    #
    # * <tt>:default</tt> - Default value for the scope. Whenever supplied the scope
    #                       is always called.
    #
    # * <tt>:allow_blank</tt> - Blank values are not sent to scopes by default. Set to true to overwrite.
    #
    # == Block usage
    #
    # has_scope also accepts a block. The controller, current scope and value are yielded
    # to the block so the user can apply the scope on its own. This is useful in case we
    # need to manipulate the given value:
    #
    #   has_scope :category do |controller, scope, value|
    #     value != "all" ? scope.by_category(value) : scope
    #   end
    #
    #   has_scope :not_voted_by_me, :type => :boolean do |controller, scope|
    #     scope.not_voted_by(controller.current_user.id)
    #   end
    #
    def has_scope(*scopes, &block)
      options = scopes.extract_options!
      options.symbolize_keys!
      options.assert_valid_keys(:type, :only, :except, :if, :unless, :default, :as, :using, :allow_blank)

      if options.key?(:using)
        if options.key?(:type) && options[:type] != :hash
          raise "You cannot use :using with another :type different than :hash"
        else
          options[:type] = :hash
        end

        options[:using] = Array(options[:using])
      end

      options[:only]   = Array(options[:only])
      options[:except] = Array(options[:except])

      self.scopes_configuration = (self.scopes_configuration || {}).dup

      scopes.each do |scope|
        self.scopes_configuration[scope] ||= { :as => scope, :type => :default, :block => block }
        self.scopes_configuration[scope] = self.scopes_configuration[scope].merge(options)
      end
    end
  end

  protected

  # Receives an object where scopes will be applied to.
  #
  #   class GraduationsController < InheritedResources::Base
  #     has_scope :featured, :type => true, :only => :index
  #     has_scope :by_degree, :only => :index
  #
  #     def index
  #       @graduations = apply_scopes(Graduation).all
  #     end
  #   end
  #
  def apply_scopes(target, hash=params)
    return target unless scopes_configuration

    self.scopes_configuration.each do |scope, options|
      next unless apply_scope_to_action?(options)
      key = options[:as]

      if hash.key?(key)
        value, call_scope = hash[key], true
      elsif options.key?(:default)
        value, call_scope = options[:default], true
        value = value.call(self) if value.is_a?(Proc)
      end

      value = parse_value(options[:type], key, value)

      if call_scope && (value.present? || options[:allow_blank])
        current_scopes[key] = value
        target = call_scope_by_type(options[:type], scope, target, value, options)
      end
    end

    target
  end

  # Set the real value for the current scope if type check.
  def parse_value(type, key, value) #:nodoc:
    if type == :boolean
      TRUE_VALUES.include?(value)
    elsif value && ALLOWED_TYPES[type].none?{ |klass| value.is_a?(klass) }
      raise "Expected type :#{type} in params[:#{key}], got #{value.class}"
    else
      value
    end
  end

  # Call the scope taking into account its type.
  def call_scope_by_type(type, scope, target, value, options) #:nodoc:
    block = options[:block]

    if type == :boolean
      block ? block.call(self, target) : target.send(scope)
    elsif value && options.key?(:using)
      value = value.values_at(*options[:using])
      block ? block.call(self, target, value) : target.send(scope, *value)
    else
      block ? block.call(self, target, value) : target.send(scope, value)
    end
  end

  # Given an options with :only and :except arrays, check if the scope
  # can be performed in the current action.
  def apply_scope_to_action?(options) #:nodoc:
    return false unless applicable?(options[:if], true) && applicable?(options[:unless], false)

    if options[:only].empty?
      options[:except].empty? || !options[:except].include?(action_name.to_sym)
    else
      options[:only].include?(action_name.to_sym)
    end
  end

  # Evaluates the scope options :if or :unless. Returns true if the proc
  # method, or string evals to the expected value.
  def applicable?(string_proc_or_symbol, expected) #:nodoc:
    case string_proc_or_symbol
      when String
        eval(string_proc_or_symbol) == expected
      when Proc
        string_proc_or_symbol.call(self) == expected
      when Symbol
        send(string_proc_or_symbol) == expected
      else
        true
    end
  end

  # Returns the scopes used in this action.
  def current_scopes
    @current_scopes ||= {}
  end
end

ActionController::Base.send :include, HasScope
