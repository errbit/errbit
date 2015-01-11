describe "problems/show.html.ics", type: 'view' do
  let(:problem) { Fabricate(:problem) }

  before do
    allow(view).to receive(:problem).and_return(problem)
  end

  it 'should work' do
    render :template => 'problems/show', :formats => [:ics], :handlers => [:haml]
  end
end
