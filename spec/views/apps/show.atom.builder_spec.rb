describe "apps/show.atom.builder", type: 'view' do
  let(:app) { stub_model(App) }
  let(:problems) { [stub_model(Problem, message: 'foo', app: app)] }

  before do
    allow(view).to receive(:app).and_return(app)
    allow(view).to receive(:problems).and_return(problems)
  end

  context "with errs" do
    it 'see the errs message' do
      render
      expect(rendered).to match(problems.first.message)
    end
  end
end
