describe "problems/index.html.haml", type: 'view' do
  let(:problem_1) { Fabricate(:problem, first_notice_at: Time.parse("2012-10-01 08:23:46")) }
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

  describe "date filter" do
    before do
      allow(Date).to receive(:today).and_return("2019-09-28")
    end

    it "has 'from' input field with date of first noticed problem" do
      render
      expect(rendered).to have_selector('input[name="from"][data-value="2012-10-01"]')
    end

    it "has 'until' input field with date of today" do
      render
      expect(rendered).to have_selector('input[name="until"][data-value="2019-09-28"]')
    end

    context "without any problems" do
      before { Problem.destroy_all }

      it "sets both input fields with todays date" do
        render
        expect(rendered).to have_selector('input[name="from"][data-value="2019-09-28"]')
        expect(rendered).to have_selector('input[name="until"][data-value="2019-09-28"]')
      end
    end
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
