module AppsHelper
  def link_to_copy_attributes_from_other_app
    if App.count > 1
      html =  link_to('copy settings from another app', '#',
                       :class => 'button copy_config')
      html << select("duplicate", "app",
                     App.all.reject{|a| a == @app }.
                     collect{|p| [ p.name, p.id ] }, {:include_blank => "[choose app]"},
                     {:class => "choose_other_app", :style => "display: none;"})
      return html
    end
  end

  def any_github_repos?
    detect_any_apps_with_attributes unless @any_github_repos
    @any_github_repos
  end

  def any_issue_trackers?
    detect_any_apps_with_attributes unless @any_issue_trackers
    @any_issue_trackers
  end

  def any_deploys?
    detect_any_apps_with_attributes unless @any_deploys
    @any_deploys
  end

  private

  def detect_any_apps_with_attributes
    @any_github_repos = @any_issue_trackers = @any_deploys = false
    @apps.each do |app|
      @any_github_repos   ||= app.github_repo?
      @any_issue_trackers ||= app.issue_tracker_configured?
      @any_deploys        ||= !!app.last_deploy_at
    end
  end
end

