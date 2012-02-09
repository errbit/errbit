module Lighthouse
  # Find projects
  #
  #   Lighthouse::Project.find(:all) # find all projects for the current account.
  #   Lighthouse::Project.find(44)   # find individual project by ID
  #
  # Creating a Project
  #
  #   project = Lighthouse::Project.new(:name => 'Ninja Whammy Jammy')
  #   project.save
  #   # => true
  #
  # Creating an OSS project
  # 
  #   project = Lighthouse::Project.new(:name => 'OSS Project')
  #   project.access = 'oss'
  #   project.license = 'mit'
  #   project.save
  # 
  # OSS License Mappings
  # 
  #   'mit' => "MIT License",
  #   'apache-2-0' => "Apache License 2.0",
  #   'artistic-gpl-2' => "Artistic License/GPLv2",
  #   'gpl-2' => "GNU General Public License v2",
  #   'gpl-3' => "GNU General Public License v3",
  #   'lgpl' => "GNU Lesser General Public License"
  #   'mozilla-1-1' => "Mozilla Public License 1.1"
  #   'new-bsd' => "New BSD License",
  #   'afl-3' => "Academic Free License v. 3.0"

  #
  # Updating a Project
  #
  #   project = Lighthouse::Project.find(44)
  #   project.name = "Lighthouse Issues"
  #   project.public = false
  #   project.save
  #
  # Finding tickets
  # 
  #   project = Lighthouse::Project.find(44)
  #   project.tickets
  #
  class Project < Base
    def tickets(options = {})
      Ticket.find(:all, :params => options.update(:project_id => id))
    end

    def messages(options = {})
      Message.find(:all, :params => options.update(:project_id => id))
    end

    def milestones(options = {})
      Milestone.find(:all, :params => options.update(:project_id => id))
    end

    def bins(options = {})
      Bin.find(:all, :params => options.update(:project_id => id))
    end
  
    def changesets(options = {})
      Changeset.find(:all, :params => options.update(:project_id => id))
    end

    def memberships(options = {})
      ProjectMembership.find(:all, :params => options.update(:project_id => id))
    end

    def tags(options = {})
      TagResource.find(:all, :params => options.update(:project_id => id))
    end
  end
end
