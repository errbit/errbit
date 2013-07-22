require 'spec_helper'

describe "problems/index.html.haml" do
  let(:problem_1) { Fabricate(:problem) }
  let(:problem_2) { Fabricate(:problem, :app => problem_1.app) }

  before do
    # view.stub(:app).and_return(problem.app)
    view.stub(:selected_problems).and_return([])
    view.stub(:problems).and_return(Kaminari.paginate_array([problem_1, problem_2]).page(1).per(10))
    view.stub(:params_sort).and_return('asc')
    controller.stub(:current_user) { Fabricate(:user) }
  end

  describe "with problem" do
    before { problem_1 && problem_2 }

    it 'should works' do
      render
      rendered.should have_selector('div#problem_table.problem_table')
    end
  end

end

