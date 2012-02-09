# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module String #:nodoc:

      # This module contains convenience methods for string inflection and
      # conversion.
      module Inflections

        ActiveSupport::Inflector.inflections do |inflect|
          inflect.singular(/address$/, "address")
          inflect.singular("addresses", "address")
          inflect.irregular("canvas", "canvases")
        end

        # Represents how special characters will get converted when creating a
        # composite key that should be unique and part of a url.
        CHAR_CONV = {
          " " => "-",
          "!" => "-excl-",
          "\"" => "-dblquo-",
          "#" => "-hash-",
          "$" => "-dol-",
          "%" => "-perc-",
          "&" => "-and-",
          "'" => "-quo-",
          "(" => "-oparen-",
          ")" => "-cparen-",
          "*" => "-astx-",
          "+" => "-plus-",
          "," => "-comma-",
          "-" => "-",
          "." => "-period-",
          "/" => "-fwdslsh-",
          ":" => "-colon-",
          ";" => "-semicol-",
          "<" => "-lt-",
          "=" => "-eq-",
          ">" => "-gt-",
          "?" => "-ques-",
          "@" => "-at-",
          "[" => "-obrck-",
          "\\" => "-bckslsh-",
          "]" => "-clbrck-",
          "^" => "-carat-",
          "_" => "-undscr-",
          "`" => "-bcktick-",
          "{" => "-ocurly-",
          "|" => "-pipe-",
          "}" => "-clcurly-",
          "~" => "-tilde-"
        }

        REVERSALS = {
          "asc" => "desc",
          "ascending" => "descending",
          "desc" => "asc",
          "descending" => "ascending"
        }

        # Convert the string to a collection friendly name.
        #
        # @example Collectionize the string.
        #   "namespace/model".collectionize
        #
        # @return [ String ] The string in collection friendly form.
        def collectionize
          tableize.gsub("/", "_")
        end

        # Convert this string to a key friendly string.
        #
        # @example Convert to key.
        #   "testing".identify
        #
        # @return [ String ] The key friendly string.
        def identify
          if Mongoid.parameterize_keys
            key = ""
            each_char { |c| key += (CHAR_CONV[c] || c.downcase) }; key
          else
            self
          end
        end

        # Get the inverted sorting option.
        #
        # @example Get the inverted option.
        #   "asc".invert
        #
        # @return [ String ] The string inverted.
        def invert
          REVERSALS[self]
        end

        # Get the string as a getter string.
        #
        # @example Get the reader/getter
        #   "model=".reader
        #
        # @return [ String ] The string stripped of "=".
        def reader
          writer? ? gsub("=", "") : self
        end

        # Is this string a writer?
        #
        # @example Is the string a setter method?
        #   "model=".writer?
        #
        # @return [ true, false ] If the string contains "=".
        def writer?
          include?("=")
        end
      end
    end
  end
end
