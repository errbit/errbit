describe "problems/index.html.haml", type: 'view' do
  let(:problem_1) { Fabricate(:problem) }
  let(:problem_2) { Fabricate(:problem, :app => problem_1.app) }

  before do
    allow(view).to receive(:selected_problems).and_return([])
    allow(view).to receive(:problems).and_return(
      Kaminari.paginate_array([problem_1, problem_2]).page(1).per(10)
    )
    allow(view).to receive(:params_sort).and_return('asc')
    allow(controller).to receive(:current_user).and_return(Fabricate(:user))
  end

  describe "with problem" do
    before { problem_1 && problem_2 }

    it 'should works' do
      render
      expect(rendered).to have_selector('div#problem_table.problem_table')
    end
  end
end
