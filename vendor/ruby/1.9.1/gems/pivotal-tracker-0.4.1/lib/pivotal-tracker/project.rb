module PivotalTracker
  class Project
    include HappyMapper

    class << self
      def all
        @found = parse(Client.connection['/projects'].get)
      end

      def find(id)
        if @found
          @found.detect { |document| document.id == id }
        else
          parse(Client.connection["/projects/#{id}"].get)
        end
      end
    end

    element :id, Integer
    element :name, String
    element :account, String
    element :week_start_day, String
    element :point_scale, String
    element :week_start_day, String
    element :velocity_scheme, String
    element :iteration_length, Integer
    element :initial_velocity, Integer
    element :current_velocity, Integer
    element :last_activity_at, DateTime
    element :use_https, Boolean

    def activities
      @activities ||= Proxy.new(self, Activity)
    end

    def iterations
      @iterations ||= Proxy.new(self, Iteration)
    end

    def stories
      @stories ||= Proxy.new(self, Story)
    end

    def memberships
      @memberships ||= Proxy.new(self, Membership)
    end

    def iteration(group)
      case group.to_sym
      when :done then Iteration.done(self)
      when :current then Iteration.current(self)
      when :backlog then Iteration.backlog(self)
      else
        raise ArgumentError, "Invalid group. Use :done, :current or :backlog instead."
      end
    end
  end
end
