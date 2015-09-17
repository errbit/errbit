describe NoticeRefingerprinter do
  let(:backtrace) do
    Fabricate(:backtrace)
  end

  let(:notices) do
    5.times.map do
      Fabricate(:notice, backtrace: backtrace)
    end
  end

  it 'shits' do
    binding.pry
    1
  end
end
