# encoding: UTF-8

# --
# Copyright (C) 2008-2011 10gen Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ++

module BSON

  # A class for representing BSON Timestamps. The Timestamp type is used
  # by MongoDB internally; thus, it should be used by application developers
  # for diagnostic purposes only.
  class Timestamp
    include Enumerable

    attr_reader :seconds, :increment

    # Create a new BSON Timestamp.
    #
    # @param [Integer] seconds The number of seconds 
    # @param increment
    def initialize(seconds, increment)
      @seconds   = seconds
      @increment = increment
    end

    def to_s
      "seconds: #{seconds}, increment: #{increment}"
    end

    def ==(other)
      self.seconds == other.seconds &&
        self.increment == other.increment
    end

    # This is for backward-compatibility. Timestamps in the Ruby
    # driver used to deserialize as arrays. So we provide
    # an equivalent interface.
    #
    # @deprecated
    def [](index)
      warn "Timestamps are no longer deserialized as arrays. If you're working " +
        "with BSON Timestamp objects, see the BSON::Timestamp class. This usage will " +
        "be deprecated in Ruby Driver v2.0."
      if index == 0
        self.increment
      elsif index == 1
        self.seconds
      else
        nil
      end
    end

    # This method exists only for backward-compatibility.
    #
    # @deprecated
    def each
      i = 0
      while i < 2
        yield self[i]
        i += 1
      end
    end
  end
end
