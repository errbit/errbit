#require 'active_support'
require 'yaml'
#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license
#
# code stolen from ActiveSupport Gem
unless  String.instance_methods.include?("camelize")
  class String
    def camelize
      self.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    end
  end
end

class VEntityUpdater
  Pluralization = {
    "attach" => "attachments",
    "categories" => "multiple_categories",
    "free_busy" => "free_busies",
    "security_class" => "security_classes",
    "request_status" => "request_statuses",
    "related_to" => "multiple_related_to",
    "resources"  => "multiple_resources"
  }
  def initialize(target, defs_file)
    @target = target
    @name=File.basename(target).sub(".rb","")
    @indent = ""
    @property_map = {}
    @property_defs = YAML.load_file(defs_file)
    @all_props = {}
    @date_time_props = []
  end

  def property(prop_name_or_hash)
    if Hash === prop_name_or_hash
      name = prop_name_or_hash.keys[0]
      override_options = prop_name_or_hash[name] || {}
    else
      name = prop_name_or_hash
      override_options = {}
    end
    standard_options = @property_defs[name]
    unless standard_options
      puts "**** WARNING, no definition found for property #{name}"
      standard_options = {}
    end
    options = {'type' => 'Text', 'ruby_name' => name}.merge(standard_options).merge(override_options)
    named_property(name, options)
  end

  def indent(string)
    @outfile.puts("#{@indent}#{string}")
  end

  def comment(*strings)
    strings.each do |string|
      indent("\# #{string}")
    end
  end

  def no_doc(string)
    indent("#{string} \# :nodoc:")
  end

  def blank_line
    @outfile.puts
  end

  def describe_type(type)
    case type
    when 'date_time_or_date'
      "either DateTime or Date"
    when 'Text'
      'String'
    else
      type
    end
  end

  def describe_property(type)
    case type
    when 'date_time_or_date'
      "either RiCal::PropertyValue::DateTime or RiCal::PropertyValue::Date"
    else
      "RiCal::PropertyValue#{type}"
    end
  end

  def type_class(type)
    if type == 'date_time_or_date'
       "RiCal::PropertyValue::DateTime"
     else
       "RiCal::PropertyValue::#{type}"
     end
   end

  def cast_value(ruby_val, type)
    "#{type_class(type)}.convert(self, #{ruby_val.inspect})"
  end

  def lazy_init_var(var, options)
    const_val = options["constant_value"]
    default_val = options["default_value"]
    if options["multi"]
      puts("*** Warning default_value of #{default_val} for multi-value property #{name} ignored") if default_val
      puts("*** Warning const_value of #{const_val} for multi-value property #{name} ignored") if const_val
      if var
        "@#{var} ||= []"
      else
        "[]"
      end
    else
      puts("*** Warning default_value of #{default_val} for property #{name} with constant_value of #{const_val}") if const_val && default_val
      init_val =  const_val || default_val
      if init_val
        if var
          "@#{var} ||= #{cast_value(init_val, options["type"])}"
        else
          init_val.inspect
        end
      else
        "@#{var}"
      end
    end
  end

  def pluralize(name)
    Pluralization[name] || "#{name}s"
  end

  def named_property(name, options)
    ruby_name = options['ruby_name']
    multi = options['multi']
    type = options['type']
    rfc_ref = options['rfc_ref']
    conflicts = options['conflicts_with']
    type_constraint = options['type_constraint']
    options.keys.each do |opt_key|
      unless %w{
        ruby_name
        type
        multi
        rfc_ref
        conflicts_with
        purpose
        constant_value
        default_value
        }.include?(opt_key)
        puts "**** WARNING: unprocessed option key #{opt_key} for property #{name}"
      end
    end
    if conflicts
      mutually_exclusive(name, *conflicts)
    end
    needs_tz_access =  %w{OccurrenceList date_time_or_date DateTime Date}.include?(type)
    ruby_name = ruby_name.tr("-", "_")
    ruby_method = ruby_name.downcase
    property = "#{name.tr("-", "_").downcase}_property"
    if type_constraint != 'must_be_utc' && %w[date_time_or_date DateTime Period OccurrenceList].include?(type)
      @date_time_props << property
    end
    @all_props[property] = name.upcase
    @property_map[name.upcase] = :"#{property}_from_string"
    parent_set = needs_tz_access ? " ? property_value.for_parent(self) : nil" : ""
    if type == 'date_time_or_date'
      line_evaluator = "RiCal::PropertyValue::DateTime.or_date(self, line)"
    else
      line_evaluator = "#{type_class(type)}.new(self, line)"
    end
    
    if %w{Array, OccurrenceList}.include?(type)
      ruby_val_parm = "*ruby_value"
      val_parm = "*val"
    else
      ruby_val_parm = "ruby_value"
      val_parm = "val"
    end
    blank_line
    if multi
      comment(
        "return the the #{name.upcase} property",
        "which will be an array of instances of #{describe_property(type)}"
      )
      comment("", "[purpose (from RFC 2445)]", options["purpose"]) if options["purpose"]
      comment("", "see RFC 2445 #{rfc_ref}") if rfc_ref
      indent("def #{property}")
      indent("  #{lazy_init_var(property,options)}")
      indent("end")
      unless (options["constant_value"])
        plural_ruby_method = pluralize(ruby_method)
        blank_line
        comment("set the the #{name.upcase} property")
        comment("one or more instances of #{describe_property(type)} may be passed to this method")
        indent("def #{property}=(*property_values)")
        if needs_tz_access
          indent("  @#{property}= property_values.map{|prop| prop.for_parent(self)}")
        else
          indent("  @#{property}= property_values")
        end
        indent("end")
        blank_line
        comment("set the value of the #{name.upcase} property to multiple values")
        comment("one or more instances of #{describe_type(type)} may be passed to this method")
        indent("def #{plural_ruby_method}=(ruby_values)")
        indent("  @#{property} = ruby_values.map {|val| #{type_class(type)}.convert(self, #{val_parm})}")
        indent("end")
        blank_line
        comment("set the value of the #{name.upcase} property to a single value")
        comment("one instance of #{describe_type(type)} may be passed to this method")
        indent("def #{ruby_method}=(#{ruby_val_parm})")
        indent("  @#{property} = [#{type_class(type)}.convert(self, #{ruby_val_parm})]")
        indent("end")
        blank_line
        comment("add one or more values to the #{name.upcase} property")
        comment("one or more instances of #{describe_type(type)} may be passed to this method")
        indent("def  add_#{plural_ruby_method}(*ruby_values)")
        indent(" ruby_values.each {|val|  self.#{property} << #{type_class(type)}.convert(self, #{val_parm})}")
        indent("end")
        blank_line
        comment("add one value to the #{name.upcase} property")
        comment("one instances of #{describe_type(type)} may be passed to this method")
        indent("def  add_#{ruby_method}(#{ruby_val_parm})")
        indent(" self.#{property} << #{type_class(type)}.convert(self, #{ruby_val_parm})")
        indent("end")
        blank_line
        comment("remove one or more values from the #{name.upcase} property")
        comment("one or more instances of #{describe_type(type)} may be passed to this method")
        indent("def  remove_#{plural_ruby_method}(*ruby_values)")
        indent(" ruby_values.each {|val|  self.#{property}.delete(#{type_class(type)}.convert(self, #{val_parm}))}")
        indent("end")
        blank_line
        comment("remove one value from the #{name.upcase} property")
        comment("one instances of #{describe_type(type)} may be passed to this method")
        indent("def  remove_#{ruby_method}(#{ruby_val_parm})")
        indent(" self.#{property}.delete(#{type_class(type)}.convert(self, #{ruby_val_parm}))")
        indent("end")
      end
      blank_line
      comment("return the value of the #{name.upcase} property")
      comment("which will be an array of instances of #{describe_type(type)}")
      indent("def #{ruby_method}")
      indent("  #{property}.map {|prop| prop ? prop.ruby_value : prop}")
      indent("end")
      blank_line
    no_doc("def #{property}_from_string(line)")
      indent("  #{property} << #{line_evaluator}")
      indent("end")
    else
      comment(
        "return the the #{name.upcase} property",
        "which will be an instances of #{describe_property(type)}"
      )
      comment("", "[purpose (from RFC 2445)]", options["purpose"]) if options["purpose"]
      comment("", "see RFC 2445 #{rfc_ref}") if rfc_ref
      indent("def #{property}")
      indent("  #{lazy_init_var(property,options)}")
      indent("end")
      unless (options["constant_value"])
        blank_line
        comment("set the #{name.upcase} property")
        comment("property value should be an instance of #{describe_property(type)}")
        indent("def #{property}=(property_value)")
        indent("  @#{property} = property_value#{parent_set}")
        if conflicts
          conflicts.each do |conflict|
            indent("  @#{conflict}_property = nil")
          end
        end
        indent("end")
        blank_line
        comment("set the value of the #{name.upcase} property")
        indent("def #{ruby_method}=(ruby_value)")
        indent("  self.#{property}= #{type_class(type)}.convert(self, ruby_value)")
        indent("end")
      end
      blank_line
      comment("return the value of the #{name.upcase} property")
      comment("which will be an instance of #{describe_type(type)}")
      indent("def #{ruby_method}")
      indent("  #{property} ? #{property}.ruby_value : nil")
      indent("end")
      blank_line
      no_doc("def #{property}_from_string(line)")
      indent("  @#{property} = #{line_evaluator}")
      indent("end")
      @outfile.puts
    end
  end

  def mutually_exclusive *prop_names
    exclusives = prop_names.map {|str| :"#{str}_property"}.sort {|a, b| a.to_s <=> b.to_s}
    unless mutually_exclusive_properties.include?(exclusives)
      mutually_exclusive_properties << prop_names.map {|str| :"#{str}_property"}
    end
  end

  def mutually_exclusive_properties
    @mutually_exclusive_properties ||= []
  end

  def generate_support_methods
    blank_line
    indent("def export_properties_to(export_stream) #:nodoc:")
    @all_props.each do |prop_attr, prop_name|
      indent("  export_prop_to(export_stream, #{prop_name.inspect}, @#{prop_attr})")
    end
    indent("end")
    blank_line
    indent("def ==(o) #:nodoc:")
    indent("  if o.class == self.class")
    @all_props.keys.each_with_index do |prop_name, i|
      and_str = i < @all_props.length - 1 ? " &&" : ""
      indent("  (#{prop_name} == o.#{prop_name})#{and_str}")
    end
    indent("  else")
    indent("     super")
    indent("  end")
    indent("end")
    blank_line
    indent("def initialize_copy(o) #:nodoc:")
    indent("  super")
    @all_props.each_key do |prop_name|
      indent("  #{prop_name} = #{prop_name} && #{prop_name}.dup")
    end
    indent("end")
    blank_line
    indent("def add_date_times_to(required_timezones) #:nodoc:")
    @date_time_props.each do | prop_name|
      indent("  add_property_date_times_to(required_timezones, #{prop_name})")
    end
    indent("end")
    blank_line
    indent("module ClassMethods #:nodoc:")
    indent("  def property_parser #:nodoc:")
    indent("    #{@property_map.inspect}")
    indent("  end")
    indent("end")
    blank_line
    indent("def self.included(mod) #:nodoc:")
    indent("  mod.extend ClassMethods")
    indent("end")
    blank_line
    indent("def mutual_exclusion_violation #:nodoc:")
    if mutually_exclusive_properties.empty?
      indent("  false")
    else
      mutually_exclusive_properties.each do |mutex_set|
        indent("  return true if #{mutex_set.inspect}.inject(0) {|sum, prop| send(prop) ? sum + 1 : sum} > 1")
      end
      indent("  false")
    end
    indent "end"
  end

  def update
    File.open(File.join(File.dirname(__FILE__), '..', 'lib', 'ri_cal',  'properties' , "#{@name}.rb"), 'w') do |ruby_out_file|
      @outfile = ruby_out_file
      module_name = @name.camelize
      class_name = module_name.sub(/Properties$/, "")
      ruby_out_file.puts("module RiCal")
      ruby_out_file.puts("  module Properties #:nodoc:")
      @indent = "    "
      ruby_out_file.puts("    #- ©2009 Rick DeNatale")
      ruby_out_file.puts("    #- All rights reserved. Refer to the file README.txt for the license")
      ruby_out_file.puts("    #")
      ruby_out_file.puts("    # Properties::#{module_name} provides property accessing methods for the #{class_name} class")
      ruby_out_file.puts("    # This source file is generated by the  rical:gen_propmodules rake tasks, DO NOT EDIT")
      ruby_out_file.puts("    module #{module_name}")
      @indent = "      "
      YAML.load_file(File.join(File.dirname(__FILE__), '..', 'component_attributes', "#{@name}.yml")).each do |att_def|
        property(att_def)
      end
      generate_support_methods
      ruby_out_file.puts("    end")
      ruby_out_file.puts("  end")
      ruby_out_file.puts("end")
    end
    @outfile = nil
  end
end

def updateTask srcGlob, taskSymbol
  targetDir = File.join(File.dirname(__FILE__), '..', 'lib', 'ri_cal', 'properties')
  defsFile = File.join(File.dirname(__FILE__), '..', 'component_attributes', 'component_property_defs.yml')
  FileList[srcGlob].each do |f|
    unless f == defsFile
      target = File.join targetDir, File.basename(f).gsub(".yml", ".rb")
      file target => [f, defsFile, __FILE__] do |t|
        VEntityUpdater.new(target, defsFile).update
      end
      task taskSymbol => target
    end
  end
end


namespace :rical do

  desc '(RE)Generate VEntity attributes'
  task :gen_propmodules do |t|
  end

  updateTask File.join(File.dirname(__FILE__), '..', '/component_attributes', '*.yml'), :gen_propmodules

end  # namespace :rical

desc 'add or update copyright in code and specs'
task :copyrights do
    require 'mmcopyrights'
    MM::Copyrights.process('lib', "rb", "#-", IO.read('copyrights.txt'))
    MM::Copyrights.process('spec', "rb", "#-", IO.read('copyrights.txt'))
end
