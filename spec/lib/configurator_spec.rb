# frozen_string_literal: true

require "rails_helper"

RSpec.describe Configurator do
  before do
    allow(ENV).to receive(:[]).and_return(nil)
    allow(ENV).to receive(:[]).with("VARONE").and_return("zoom")
    allow(ENV).to receive(:[]).with("VARTHREE").and_return("zipp")
  end

  it "takes the first existing env, second item" do
    result = Configurator.run(two: ["VARTWO", "VARTHREE"])
    expect(result.two).to eq("zipp")
  end

  it "takes the first existing env, first item" do
    result = Configurator.run(three: ["VARTHREE", "VARONE"])
    expect(result.three).to eq("zipp")
  end

  it "provides nothing for missing variables" do
    result = Configurator.run(four: ["VAREIGHTY"])
    expect(result.four).to eq(nil)
  end

  it "overrides existing variables" do
    result = Configurator.run(one: ["VARONE", ->(_values) { "oveRIIIDE" }])
    expect(result.one).to eq("oveRIIIDE")
  end

  it "overrides can refer to other values" do
    result = Configurator.run(one: ["VARONE", ->(values) { values[:one] }],
      three: ["VARTHREE"])
    expect(result.one).to eq("zoom")
  end

  it "extracts symbol values" do
    allow(ENV).to receive(:[]).with("MYSYMBOL").and_return(":asymbol")
    result = Configurator.run(mysymbol: ["MYSYMBOL"])
    expect(result.mysymbol).to eq(:asymbol)
  end

  it "extracts array values" do
    allow(ENV).to receive(:[]).with("MYARRAY").and_return("[one,two,three]")
    result = Configurator.run(myarray: ["MYARRAY"])
    expect(result.myarray).to eq(["one", "two", "three"])
  end

  it "extracts booleans" do
    allow(ENV).to receive(:[]).with("MYBOOLEAN").and_return("true")
    result = Configurator.run(myboolean: ["MYBOOLEAN"])
    expect(result.myboolean).to eq(true)
  end

  it "extracts numbers" do
    allow(ENV).to receive(:[]).with("MYNUMBER").and_return("0")
    result = Configurator.run(mynumber: ["MYNUMBER"])
    expect(result.mynumber).to eq(0)
  end

  it "parses empty variables" do
    allow(ENV).to receive(:[]).with("EMPTYVAR").and_return("")
    result = Configurator.run(emptyvar: ["EMPTYVAR"])
    expect(result.emptyvar).to eq("")
  end
end
