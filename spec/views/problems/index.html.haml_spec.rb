describe "problems/index.html.haml", type: 'view' do
  let(:problem_1) { Fabricate(:problem) }
  let(:problem_2) { Fabricate(:problem, app: problem_1.app) }

  before do
    allow(view).to receive(:selected_problems).and_return([])
    allow(view).to receive(:all_errs).and_return(false)
    allow(view).to receive(:problems).and_return(
      Kaminari.paginate_array([problem_1, problem_2]).page(1).per(10)
    )
    allow(view).to receive(:params_sort).and_return('last_notice_at')
    allow(view).to receive(:params_order).and_return('asc')
    allow(controller).to receive(:current_user).and_return(Fabricate(:user))
  end

  describe "with problem" do
    before { problem_1 && problem_2 }

    it 'should works' do
      render
      expect(rendered).to have_selector('div#problem_table.problem_table')
    end
  end

  describe "show/hide resolved button behavior" do
    it "displays unresolved errors title and button" do
      allow(view).to receive(:all_errs).and_return(false)
      render
      expect(view.content_for(:title)).to match 'Unresolved Errors'
      expect(view.content_for(:action_bar)).to have_link 'show resolved'
    end

    it "displays all errors title and button" do
      allow(view).to receive(:all_errs).and_return(true)
      render
      expect(view.content_for :title).to match 'All Errors'
      expect(view.content_for :action_bar).to have_link 'hide resolved'
    end
  end
end
