# -*- encoding: utf-8 -*-
require 'helper'

describe Octokit::Client::Organizations do

  before do
    @client = Octokit::Client.new(:login => 'sferik')
  end

  describe ".organization" do

    it "should return an organization" do
      stub_get("/api/v2/json/organizations/codeforamerica").
        to_return(:body => fixture("v2/organization.json"))
      organization = @client.organization("codeforamerica")
      organization.name.should == "Code For America"
    end

  end

  describe ".update_organization" do

    it "should update an organization" do
      stub_put("/api/v2/json/organizations/codeforamerica").
        with(:name => "Code For America").
        to_return(:body => fixture("v2/organization.json"))
      organization = @client.update_organization("codeforamerica", {:name => "Code For America"})
      organization.name.should == "Code For America"
    end

  end

  describe ".organizations" do

    context "with an org passed" do

      it "should return all organizations for a user" do
        stub_get("/api/v2/json/user/show/sferik/organizations").
          to_return(:body => fixture("v2/organizations.json"))
        organizations = @client.organizations("sferik")
        organizations.first.name.should == "Hubcap"
      end

    end

    context "without an org passed" do

      it "should return all organizations for a user" do
        stub_get("/api/v2/json/organizations").
          to_return(:body => fixture("v2/organizations.json"))
        organizations = @client.organizations
        organizations.first.name.should == "Hubcap"
      end

    end

  end

  describe ".organization_repositories" do

    context "with an org passed" do

      it "should return all public repositories for an organization" do
        stub_get("/api/v2/json/organizations/codeforamerica/public_repositories").
          to_return(:body => fixture("v2/repositories.json"))
        repositories = @client.organization_repositories("codeforamerica")
        repositories.first.name.should == "One40Proof"
      end

    end

    context "without an org passed" do

      it "should return all organization repositories for a user" do
        stub_get("/api/v2/json/organizations/repositories").
          to_return(:body => fixture("v2/repositories.json"))
        repositories = @client.organization_repositories
        repositories.first.name.should == "One40Proof"
      end

    end

  end

  describe ".organization_members" do

    it "should return all public members of an organization" do
      stub_get("/api/v2/json/organizations/codeforamerica/public_members").
        to_return(:body => fixture("v2/users.json"))
      users = @client.organization_members("codeforamerica")
      users.first.name.should == "Erik Michaels-Ober"
    end

  end

  describe ".organization_teams" do

    it "should return all teams for an organization" do
      stub_get("/api/v2/json/organizations/codeforamerica/teams").
        to_return(:body => fixture("v2/teams.json"))
      teams = @client.organization_teams("codeforamerica")
      teams.first.name.should == "Fellows"
    end

  end

  describe ".create_team" do

    it "should create a team" do
      stub_post("/api/v2/json/organizations/codeforamerica/teams").
        with(:name => "Fellows").
        to_return(:body => fixture("v2/team.json"))
      team = @client.create_team("codeforamerica", {:name => "Fellows"})
      team.name.should == "Fellows"
    end

  end

  describe ".team" do

    it "should return a team" do
      stub_get("/api/v2/json/teams/32598").
        to_return(:body => fixture("v2/team.json"))
      team = @client.team(32598)
      team.name.should == "Fellows"
    end

  end

  describe ".update_team" do

    it "should update a team" do
      stub_put("/api/v2/json/teams/32598").
        with(:name => "Fellows").
        to_return(:body => fixture("v2/team.json"))
      team = @client.update_team(32598, :name => "Fellows")
      team.name.should == "Fellows"
    end

  end

  describe ".delete_team" do

    it "should delete a team" do
      stub_delete("/api/v2/json/teams/32598").
        to_return(:body => fixture("v2/team.json"))
      team = @client.delete_team(32598)
      team.name.should == "Fellows"
    end

  end

  describe ".delete_team" do

    it "should delete a team" do
      stub_delete("/api/v2/json/teams/32598").
        to_return(:body => fixture("v2/team.json"))
      team = @client.delete_team(32598)
      team.name.should == "Fellows"
    end

  end

  describe ".team_members" do

    it "should return team members" do
      stub_get("/api/v2/json/teams/32598/members").
        to_return(:body => fixture("v2/users.json"))
      users = @client.team_members(32598)
      users.first.name.should == "Erik Michaels-Ober"
    end

  end

  describe ".add_team_member" do

    it "should add a team member" do
      stub_post("/api/v2/json/teams/32598/members").
        with(:name => "sferik").
        to_return(:body => fixture("v2/user.json"))
      user = @client.add_team_member(32598, "sferik")
      user.name.should == "Erik Michaels-Ober"
    end

  end

  describe ".remove_team_member" do

    it "should remove a team member" do
      stub_delete("/api/v2/json/teams/32598/members").
        with(:query => {:name => "sferik"}).
        to_return(:body => fixture("v2/user.json"))
      user = @client.remove_team_member(32598, "sferik")
      user.name.should == "Erik Michaels-Ober"
    end

  end

  describe ".team_repositories" do

    it "should return team repositories" do
      stub_get("/api/v2/json/teams/32598/repositories").
        to_return(:body => fixture("v2/repositories.json"))
      repositories = @client.team_repositories(32598)
      repositories.first.name.should == "One40Proof"
    end

  end

  describe ".add_team_repository" do

    it "should add a team repository" do
      stub_post("/api/v2/json/teams/32598/repositories").
        with(:name => "reddavis/One40Proof").
        to_return(:body => fixture("v2/repositories.json"))
      repositories = @client.add_team_repository(32598, "reddavis/One40Proof")
      repositories.first.name.should == "One40Proof"
    end

  end

  describe ".remove_team_repository" do

    it "should remove a team repository" do
      stub_delete("/api/v2/json/teams/32598/repositories").
        with(:query => {:name => "reddavis/One40Proof"}).
        to_return(:body => fixture("v2/repositories.json"))
      repositories = @client.remove_team_repository(32598, "reddavis/One40Proof")
      repositories.first.name.should == "One40Proof"
    end

  end

end
