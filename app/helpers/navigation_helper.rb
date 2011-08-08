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
    current_action     = controller.action_name.to_sym

    sections =  case matches
                when Hash
                  matches
                when Array
                  s = {}
                  matches.each {|c| s[c] = :all}
                  s
                else
                  {matches => :all}
                end

    active = nil
    sections.each do |controller, actions|
      actions = ([] << actions) unless actions.kind_of?(Array)
      active = ' active' if current_controller == controller && (actions.include?(:all) || actions.include?(current_action))
    end
    active
  end

end