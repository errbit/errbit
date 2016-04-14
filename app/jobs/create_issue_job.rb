require 'render_anywhere'

class CreateIssueJob < SidekiqJob
  include RenderAnywhere
  def perform(problem_id)
    set_render_anywhere_helpers(HashHelper)

    problem = ProblemDecorator.new Problem.find(problem_id)
    notices = problem.object.notices.reverse_ordered.page(1).per(1)
    notice  = NoticeDecorator.new notices.first


    issue = Issue.new(problem: problem, user: User.new)
    issue.body = render issue.render_body_args[0],
      :formats => [:md],
      :locals => { :problem => problem, :notice => notice }

    return true unless issue.save
  end
end
