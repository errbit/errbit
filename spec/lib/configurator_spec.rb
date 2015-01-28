describe Configurator do
  before(:each) do
    allow(ENV).to receive(:[]).and_return(nil)
    allow(ENV).to receive(:[]).with('VARONE').and_return('zoom')
    allow(ENV).to receive(:[]).with('VARTHREE').and_return('zipp')
  end

  it 'takes the first existing env, second item' do
    result = Configurator.run({ two: ['VARTWO', 'VARTHREE'] })
    expect(result.two).to eq('zipp')
  end

  it 'takes the first existing env, first item' do
    result = Configurator.run({ three: ['VARTHREE', 'VARONE'] })
    expect(result.three).to eq('zipp')
  end

  it 'provides nothing for missing variables' do
    result = Configurator.run({ four: ['VAREIGHTY'] })
    expect(result.four).to be_nil
  end

  it 'overrides existing variables' do
    result = Configurator.run({
      one: ['VARONE', ->(values) { 'oveRIIIDE' } ]
    })
    expect(result.one).to eq('oveRIIIDE')
  end

  it 'overrides can refer to other values' do
    result = Configurator.run({
      one: ['VARONE', ->(values) { values[:one] } ],
      three: ['VARTHREE' ]
    })
    expect(result.one).to eq('zoom')
  end
end
