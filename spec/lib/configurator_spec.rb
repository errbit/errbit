describe Configurator do
  before(:each) do
    allow(ENV).to receive(:[]).and_return(nil)
    allow(ENV).to receive(:[]).with('VARONE').and_return('zoom')
    allow(ENV).to receive(:[]).with('VARTHREE').and_return('zipp')
  end

  it 'takes the first existing env, second item' do
    result = Configurator.run(two: %w(VARTWO VARTHREE))
    expect(result.two).to eq('zipp')
  end

  it 'takes the first existing env, first item' do
    result = Configurator.run(three: %w(VARTHREE VARONE))
    expect(result.three).to eq('zipp')
  end

  it 'provides nothing for missing variables' do
    result = Configurator.run(four: ['VAREIGHTY'])
    expect(result.four).to be_nil
  end

  it 'overrides existing variables' do
    result = Configurator.run(one: ['VARONE', ->(_values) { 'oveRIIIDE' }])
    expect(result.one).to eq('oveRIIIDE')
  end

  it 'overrides can refer to other values' do
    result = Configurator.run(one:   ['VARONE', ->(values) { values[:one] }],
                              three: ['VARTHREE'])
    expect(result.one).to eq('zoom')
  end

  it 'extracts symbol values' do
    allow(ENV).to receive(:[]).with('MYSYMBOL').and_return(':asymbol')
    result = Configurator.run(mysymbol: ['MYSYMBOL'])
    expect(result.mysymbol).to be(:asymbol)
  end

  it 'extracts array values' do
    allow(ENV).to receive(:[]).with('MYARRAY').and_return('[one,two,three]')
    result = Configurator.run(myarray: ['MYARRAY'])
    expect(result.myarray).to eq(%w(one two three))
  end

  it 'extracts booleans' do
    allow(ENV).to receive(:[]).with('MYBOOLEAN').and_return('true')
    result = Configurator.run(myboolean: ['MYBOOLEAN'])
    expect(result.myboolean).to be(true)
  end

  it 'extracts numbers' do
    allow(ENV).to receive(:[]).with('MYNUMBER').and_return('0')
    result = Configurator.run(mynumber: ['MYNUMBER'])
    expect(result.mynumber).to be(0)
  end

  it 'parses empty variables' do
    allow(ENV).to receive(:[]).with('EMPTYVAR').and_return('')
    result = Configurator.run(emptyvar: ['EMPTYVAR'])
    expect(result.emptyvar).to eq('')
  end
end
