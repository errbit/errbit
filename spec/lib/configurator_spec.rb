# frozen_string_literal: true

require "rails_helper"

RSpec.describe Configurator do
  before do
    allow(ENV).to receive(:[]).and_return(nil)
    allow(ENV).to receive(:[]).with("VARONE").and_return("zoom")
    allow(ENV).to receive(:[]).with("VARTHREE").and_return("zipp")
  end

  it "takes the first existing env, second item" do
    result = described_class.run(two: ["VARTWO", "VARTHREE"])

    expect(result.two).to eq("zipp")
  end

  it "takes the first existing env, first item" do
    result = described_class.run(three: ["VARTHREE", "VARONE"])

    expect(result.three).to eq("zipp")
  end

  it "provides nothing for missing variables" do
    result = described_class.run(four: ["VAREIGHTY"])

    expect(result.four).to eq(nil)
  end

  it "overrides existing variables" do
    result = described_class.run(one: ["VARONE", ->(_values) { "oveRIIIDE" }])

    expect(result.one).to eq("oveRIIIDE")
  end

  it "overrides can refer to other values" do
    result = described_class.run(one: ["VARONE", ->(values) { values[:one] }],
      three: ["VARTHREE"])

    expect(result.one).to eq("zoom")
  end

  it "extracts symbol values" do
    allow(ENV).to receive(:[]).with("MYSYMBOL").and_return(":asymbol")

    result = described_class.run(mysymbol: ["MYSYMBOL"])

    expect(result.mysymbol).to eq(:asymbol)
  end

  it "extracts array values" do
    allow(ENV).to receive(:[]).with("MYARRAY").and_return("[one,two,three]")

    result = described_class.run(myarray: ["MYARRAY"])

    expect(result.myarray).to eq(["one", "two", "three"])
  end

  it "extracts booleans" do
    allow(ENV).to receive(:[]).with("MYBOOLEAN").and_return("true")

    result = described_class.run(myboolean: ["MYBOOLEAN"])

    expect(result.myboolean).to eq(true)
  end

  it "extracts numbers" do
    allow(ENV).to receive(:[]).with("MYNUMBER").and_return("0")

    result = described_class.run(mynumber: ["MYNUMBER"])

    expect(result.mynumber).to eq(0)
  end

  it "parses empty variables" do
    allow(ENV).to receive(:[]).with("EMPTYVAR").and_return("")

    result = described_class.run(emptyvar: ["EMPTYVAR"])

    expect(result.emptyvar).to eq("")
  end

  describe "typed values" do
    it "parses booleans strictly" do
      allow(ENV).to receive(:[]).with("TRUE_VALUE").and_return("true")
      allow(ENV).to receive(:[]).with("FALSE_VALUE").and_return('"false"')

      result = described_class.run(
        true_value: {env: ["TRUE_VALUE"], type: :boolean},
        false_value: {env: ["FALSE_VALUE"], type: :boolean}
      )

      expect(result.true_value).to be(true)
      expect(result.false_value).to be(false)
    end

    it "rejects ambiguous booleans" do
      allow(ENV).to receive(:[]).with("BOOLEAN_VALUE").and_return("maybe")

      expect do
        described_class.run(boolean_value: {env: ["BOOLEAN_VALUE"], type: :boolean})
      end.to raise_error(ArgumentError, "BOOLEAN_VALUE must be true or false")
    end

    it "parses integers" do
      allow(ENV).to receive(:[]).with("INTEGER_VALUE").and_return('"2525"')

      result = described_class.run(integer_value: {env: "INTEGER_VALUE", type: :integer})

      expect(result.integer_value).to eq(2525)
    end

    it "rejects invalid integers" do
      allow(ENV).to receive(:[]).with("INTEGER_VALUE").and_return("25.25")

      expect do
        described_class.run(integer_value: {env: ["INTEGER_VALUE"], type: :integer})
      end.to raise_error(ArgumentError, /INTEGER_VALUE must contain an integer/)
    end

    it "rejects empty typed scalar values" do
      allow(ENV).to receive(:[]).with("EMPTY_BOOLEAN").and_return(" ")
      allow(ENV).to receive(:[]).with("EMPTY_INTEGER").and_return("")

      expect do
        described_class.run(empty_boolean: {env: ["EMPTY_BOOLEAN"], type: :boolean})
      end.to raise_error(ArgumentError, "EMPTY_BOOLEAN cannot be empty")

      expect do
        described_class.run(empty_integer: {env: ["EMPTY_INTEGER"], type: :integer})
      end.to raise_error(ArgumentError, "EMPTY_INTEGER cannot be empty")
    end

    it "parses string arrays from YAML and comma-separated values" do
      allow(ENV).to receive(:[]).with("YAML_ARRAY").and_return("[repo, user]")
      allow(ENV).to receive(:[]).with("CSV_ARRAY").and_return('"example.com, example.org"')
      allow(ENV).to receive(:[]).with("SINGLE_VALUE").and_return("repo")

      result = described_class.run(
        yaml_array: {env: ["YAML_ARRAY"], type: :string_array},
        csv_array: {env: ["CSV_ARRAY"], type: :string_array},
        single_value: {env: ["SINGLE_VALUE"], type: :string_array}
      )

      expect(result.yaml_array).to eq(["repo", "user"])
      expect(result.csv_array).to eq(["example.com", "example.org"])
      expect(result.single_value).to eq(["repo"])
    end

    it "rejects empty elements in typed arrays" do
      allow(ENV).to receive(:[]).with("INTEGER_ARRAY").and_return('"1,, 10,"')

      expect do
        described_class.run(integer_array: {env: ["INTEGER_ARRAY"], type: :integer_array})
      end.to raise_error(ArgumentError, "INTEGER_ARRAY must not contain empty list elements")
    end

    it "normalizes an empty typed array" do
      allow(ENV).to receive(:[]).with("EMPTY_ARRAY").and_return("[]")

      result = described_class.run(empty_array: {env: ["EMPTY_ARRAY"], type: :string_array})

      expect(result.empty_array).to eq([])
    end

    it "rejects blank typed arrays" do
      allow(ENV).to receive(:[]).with("BLANK_ARRAY").and_return(" ")

      expect do
        described_class.run(blank_array: {env: ["BLANK_ARRAY"], type: :string_array})
      end.to raise_error(ArgumentError, "BLANK_ARRAY cannot be empty")
    end

    it "parses negative integer arrays" do
      allow(ENV).to receive(:[]).with("INTEGER_ARRAY").and_return("[-1, 0, 10]")

      result = described_class.run(integer_array: {env: ["INTEGER_ARRAY"], type: :integer_array})

      expect(result.integer_array).to eq([-1, 0, 10])
    end

    it "rejects malformed array brackets" do
      allow(ENV).to receive(:[]).with("MALFORMED_ARRAY").and_return("[repo, user")

      expect do
        described_class.run(malformed_array: {env: ["MALFORMED_ARRAY"], type: :string_array})
      end.to raise_error(ArgumentError, "MALFORMED_ARRAY must contain a valid list")
    end

    it "rejects malformed YAML arrays" do
      allow(ENV).to receive(:[]).with("MALFORMED_ARRAY").and_return('[repo, "unterminated]')

      expect do
        described_class.run(malformed_array: {env: ["MALFORMED_ARRAY"], type: :string_array})
      end.to raise_error(ArgumentError, "MALFORMED_ARRAY must contain a valid list")
    end

    it "rejects typed definitions without environment names" do
      expect do
        described_class.run(value: {env: [], type: :integer})
      end.to raise_error(ArgumentError, "configuration environment names cannot be empty")
    end

    it "rejects unsupported typed values" do
      allow(ENV).to receive(:[]).with("VALUE").and_return("value")

      expect do
        described_class.run(value: {env: "VALUE", type: :float})
      end.to raise_error(ArgumentError, "Unsupported configuration type :float")
    end

    it "uses the first configured environment and applies an override" do
      allow(ENV).to receive(:[]).with("PRIMARY_PORT").and_return(nil)
      allow(ENV).to receive(:[]).with("FALLBACK_PORT").and_return("2525")

      result = described_class.run(port: {
        env: ["PRIMARY_PORT", "FALLBACK_PORT"],
        type: :integer,
        override: ->(values) { values[:port] + 1 }
      })

      expect(result.port).to eq(2526)
    end

    it "preserves typed override callbacks" do
      allow(ENV).to receive(:[]).with("PORT").and_return("2525")

      result = described_class.run(port: {
        env: ["PORT"],
        type: :integer,
        override: ->(values) { values[:port] + 1 }
      })

      expect(result.port).to eq(2526)
    end
  end
end
