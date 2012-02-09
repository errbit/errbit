module PivotalTracker
  class Membership
    include HappyMapper

    class << self
      def all(project, options={})
        parse(Client.connection["/projects/#{project.id}/memberships"].get)
      end
    end

    element :id, Integer
    element :role, String

    # Flattened Attributes from <person>...</person>
    element :name, String, :deep => true
    element :email, String, :deep => true
    element :initials, String, :deep => true

  end
end
