module NewRelic::LanguageSupport
  extend self
  
  module DataSerialization
    def self.included(base)
      # need to disable GC during marshal load in 1.8.7
      if NewRelic::LanguageSupport.using_version?('1.8.7') &&
          !NewRelic::LanguageSupport.using_engine?('jruby') &&
          !NewRelic::LanguageSupport.using_engine?('rbx')
        base.class_eval do
          def self.load(*args)
            if defined?(::GC) && ::GC.respond_to?(:disable)
              ::GC.disable
              val = super
              ::GC.enable
              val
            else
              super
            end
          end
        end
      end
    end
  end
  
  module Control
    def self.included(base)
      # need to use syck rather than psych when possible
      if defined?(::YAML::ENGINE)
        unless NewRelic::LanguageSupport.using_engine?('jruby') &&
                NewRelic::LanguageSupport.using_version?('1.9')
          base.class_eval do
            def load_newrelic_yml(*args)
              yamler = ::YAML::ENGINE.yamler
              ::YAML::ENGINE.yamler = 'syck'
              val = super
              ::YAML::ENGINE.yamler = yamler
              val
            end
          end
        end
      end
    end
  end
  
  module SynchronizedHash
    def self.included(base)
      # need to lock iteration of stats hash in 1.9.x
      if NewRelic::LanguageSupport.using_version?('1.9') ||
          NewRelic::LanguageSupport.using_engine?('jruby')
        base.class_eval do
          def each(*args, &block)
            @lock.synchronize { super }
          end
        end
      end
    end
  end
  
  def using_engine?(engine)
    if defined?(::RUBY_ENGINE)
      ::RUBY_ENGINE == engine
    else
      engine == 'ruby'
    end
  end
  
  def using_version?(version)
    numbers = version.split('.')
    numbers == ::RUBY_VERSION.split('.')[0, numbers.size]
  end
end
