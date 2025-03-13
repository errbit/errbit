module NavigationHelper
  # Returns ' active' if you are on a given controller
  #  - active_if_here(:users) => ' active' if users controller
  # Or on one of a list of controllers
  # - active_if_here([:users, :blogs, :comments])
  # Or on certain action(s) in a certain controller
  #  - active_if_here(:users => :index, :blogs => [:create, :update], :comments)
  #
  # Useful for navigation elements that have a certain state when your on a given page.
  # Returns nil if there are no matches so when passing:
  #  link_to 'link', '#', :class => active_if_here(:users)
  # will not even set a class attribute if nil is passed back.
  def active_if_here(matches)
    current_controller = controller.controller_name.to_sym
    current_action = controller.action_name.to_sym

    sections = case matches
    when Hash
      matches
    when Array
      s = {}
      matches.each { |c| s[c] = :all }
      s
    else
      {matches => :all}
    end

    active = nil
    sections.each do |controller, actions|
      actions = Array(actions)
      active = " active" if current_controller == controller && (actions.include?(:all) || actions.include?(current_action))
    end
    active
  end

  # Returns the page number in reverse order.
  # Needed when reverse chronological paginating notices but
  # want to display the actual chronological occurrence number.
  #
  # E.G. - Given 6 notices, page 2 shows the second from last
  # occurrence indexed by 1, but it is diplaying the 5th ever
  # occurence of that error.
  def page_count_from_end(current_page, total_pages)
    (total_pages.to_i - current_page.to_i) + 1
  end
end
