namespace :errbit do
  
  desc "Migrates Errs so that they are embedded in Problems"
  task :upgrade => :environment do
    App.db['errs'].find.each do |err_attrs|
      problem_attrs = {
        :app_id           => err_attrs.delete('app_id'),
        :issue_link       => err_attrs.delete('issue_link'),
        :last_notice_at   => err_attrs.delete('last_notice_at'),
        :resolved         => err_attrs.delete('resolved')
      }
      problem = Problem.create!(problem_attrs)
      problem.errs.create!(err_attrs)
    end
  end
  
end