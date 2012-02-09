# -*- encoding: utf-8 -*-
require 'helper'

describe Octokit::Client::Repositories do

  before do
    @client = Octokit::Client.new(:login => 'sferik')
  end

  describe ".search_user" do

    it "should return matching repositories" do
      stub_get("/api/v2/json/repos/search/One40Proof").
        to_return(:body => fixture("v2/repositories.json"))
      repositories = @client.search_repositories("One40Proof")
      repositories.first.name.should == "One40Proof"
    end

  end

  describe ".repository" do

    it "should return the matching repository" do
      stub_get("/api/v2/json/repos/show/sferik/rails_admin").
        to_return(:body => fixture("v2/repository.json"))
      repository = @client.repository("sferik/rails_admin")
      repository.name.should == "rails_admin"
    end

  end

  describe ".update_repository" do

    it "should update the matching repository" do
      description = "RailsAdmin is a Rails 3 engine that provides an easy-to-use interface for managing your data"
      stub_post("/api/v2/json/repos/show/sferik/rails_admin").
        with(:values => {:description => description}).
        to_return(:body => fixture("v2/repository.json"))
      repository = @client.update_repository("sferik/rails_admin", :description => description)
      repository.description.should == description
    end

  end

  describe ".repositories" do

    context "with a username passed" do

      it "should return user's repositories" do
        stub_get("/api/v2/json/repos/show/sferik").
          to_return(:body => fixture("v2/repositories.json"))
        repositories = @client.repositories("sferik")
        repositories.first.name.should == "One40Proof"
      end

    end

    context "without a username passed" do

      it "should return authenticated user's repositories" do
        stub_get("/api/v2/json/repos/show/sferik").
          to_return(:body => fixture("v2/repositories.json"))
        repositories = @client.repositories
        repositories.first.name.should == "One40Proof"
      end

    end

  end

  describe ".watch" do

    it "should watch a repository" do
      stub_post("/api/v2/json/repos/watch/sferik/rails_admin").
        to_return(:body => fixture("v2/repository.json"))
      repository = @client.watch("sferik/rails_admin")
      repository.name.should == "rails_admin"
    end

  end

  describe ".unwatch" do

    it "should unwatch a repository" do
      stub_post("/api/v2/json/repos/unwatch/sferik/rails_admin").
        to_return(:body => fixture("v2/repository.json"))
      repository = @client.unwatch("sferik/rails_admin")
      repository.name.should == "rails_admin"
    end

  end

  describe ".fork" do

    it "should fork a repository" do
      stub_post("/api/v2/json/repos/fork/sferik/rails_admin").
        to_return(:body => fixture("v2/repository.json"))
      repository = @client.fork("sferik/rails_admin")
      repository.name.should == "rails_admin"
    end

  end

  describe ".create_repository" do

    it "should create a repository" do
      stub_post("/api/v2/json/repos/create").
        with(:name => "rails_admin").
        to_return(:body => fixture("v2/repository.json"))
      repository = @client.create_repository("rails_admin")
      repository.name.should == "rails_admin"
    end

  end

  describe ".delete_repository" do

    it "should return a delete token" do
      stub_post("/api/v2/json/repos/delete/sferik/rails_admin").
        to_return(:body => fixture("v2/delete_token.json"))
      delete_token = @client.delete_repository("sferik/rails_admin")
      delete_token.should == "uhihwkkkzu"
    end

  end

  describe ".delete_repository!" do

    it "should delete a repository" do
      stub_post("/api/v2/json/repos/delete/sferik/rails_admin").
        to_return(:body => fixture("v2/delete_token.json"))
      stub_post("/api/v2/json/repos/delete/sferik/rails_admin").
        with(:delete_token => "uhihwkkkzu").
        to_return(:status => 204)
      @client.delete_repo!("sferik/rails_admin")
    end

  end

  describe ".delete_repository" do

    it "should return an error for non-existant repo" do
      stub_post("/api/v2/json/repos/delete/sferik/rails_admin_failure").
        to_return(:body => fixture("v2/delete_failure.json"))
      response = @client.delete_repository("sferik/rails_admin_failure")
      response.error.should == "sferik/rails_admin_failure Repository not found"
    end

  end

  describe ".set_private" do

    it "should set a repository private" do
      stub_post("/api/v2/json/repos/set/private/sferik/rails_admin").
        to_return(:body => fixture("v2/repository.json"))
      repository = @client.set_private("sferik/rails_admin")
      repository.name.should == "rails_admin"
    end

  end

  describe ".set_public" do

    it "should set a repository public" do
      stub_post("/api/v2/json/repos/set/public/sferik/rails_admin").
        to_return(:body => fixture("v2/repository.json"))
      repository = @client.set_public("sferik/rails_admin")
      repository.name.should == "rails_admin"
    end

  end

  describe ".deploy_keys" do

    it "should return a repository's deploy keys" do
      stub_get("/api/v2/json/repos/keys/sferik/rails_admin").
        to_return(:body => fixture("v2/public_keys.json"))
      public_keys = @client.deploy_keys("sferik/rails_admin")
      public_keys.first.id.should == 103205
    end

  end

  describe ".add_deploy_key" do

    it "should add a repository deploy keys" do
      stub_post("/api/v2/json/repos/key/sferik/rails_admin/add").
        with(:title => "Moss", :key => "ssh-dss AAAAB3NzaC1kc3MAAACBAJz7HanBa18ad1YsdFzHO5Wy1/WgXd4BV+czbKq7q23jungbfjN3eo2a0SVdxux8GG+RZ9ia90VD/X+PE4s3LV60oXZ7PDAuyPO1CTF0TaDoKf9mPaHcPa6agMJVocMsgBgwviWT1Q9VgN1SccDsYVDtxkIAwuw25YeHZlG6myx1AAAAFQCgW+OvXWUdUJPBGkRJ8ML7uf0VHQAAAIAlP5G96tTss0SKYVSCJCyocn9cyGQdNjxah4/aYuYFTbLI1rxk7sr/AkZfJNIoF2UFyO5STbbratykIQGUPdUBg1a2t72bu31x+4ZYJMngNsG/AkZ2oqLiH6dJKHD7PFx2oSPalogwsUV7iSMIZIYaPa03A9763iFsN0qJjaed+gAAAIBxz3Prxdzt/os4XGXSMNoWcS03AFC/05NOkoDMrXxQnTTpp1wrOgyRqEnKz15qC5dWk1ynzK+LJXHDZGA8lXPfCjHpJO3zrlZ/ivvLhgPdDpt13MAhIJFH06hTal0woxbk/fIdY71P3kbgXC0Ppx/0S7BC+VxqRCA4/wcM+BoDbA== host").
        to_return(:body => fixture("v2/public_keys.json"))
      public_keys = @client.add_deploy_key("sferik/rails_admin", "Moss", "ssh-dss AAAAB3NzaC1kc3MAAACBAJz7HanBa18ad1YsdFzHO5Wy1/WgXd4BV+czbKq7q23jungbfjN3eo2a0SVdxux8GG+RZ9ia90VD/X+PE4s3LV60oXZ7PDAuyPO1CTF0TaDoKf9mPaHcPa6agMJVocMsgBgwviWT1Q9VgN1SccDsYVDtxkIAwuw25YeHZlG6myx1AAAAFQCgW+OvXWUdUJPBGkRJ8ML7uf0VHQAAAIAlP5G96tTss0SKYVSCJCyocn9cyGQdNjxah4/aYuYFTbLI1rxk7sr/AkZfJNIoF2UFyO5STbbratykIQGUPdUBg1a2t72bu31x+4ZYJMngNsG/AkZ2oqLiH6dJKHD7PFx2oSPalogwsUV7iSMIZIYaPa03A9763iFsN0qJjaed+gAAAIBxz3Prxdzt/os4XGXSMNoWcS03AFC/05NOkoDMrXxQnTTpp1wrOgyRqEnKz15qC5dWk1ynzK+LJXHDZGA8lXPfCjHpJO3zrlZ/ivvLhgPdDpt13MAhIJFH06hTal0woxbk/fIdY71P3kbgXC0Ppx/0S7BC+VxqRCA4/wcM+BoDbA== host")
      public_keys.first.id.should == 103205
    end

  end

  describe ".remove_deploy_key" do

    it "should remove a repository deploy keys" do
      stub_post("/api/v2/json/repos/key/sferik/rails_admin/remove").
        with(:id => 103205).
        to_return(:body => fixture("v2/public_keys.json"))
      public_keys = @client.remove_deploy_key("sferik/rails_admin", 103205)
      public_keys.first.id.should == 103205
    end

  end

  describe ".collaborators" do

    it "should return a repository's collaborators" do
      stub_get("/api/v2/json/repos/show/sferik/rails_admin/collaborators").
        to_return(:body => fixture("v2/collaborators.json"))
      collaborators = @client.collaborators("sferik/rails_admin")
      collaborators.first.should == "sferik"
    end

  end

  describe ".add_collaborator" do

    it "should add a repository collaborators" do
      stub_post("/api/v2/json/repos/collaborators/sferik/rails_admin/add/sferik").
        to_return(:body => fixture("v2/collaborators.json"))
      collaborators = @client.add_collaborator("sferik/rails_admin", "sferik")
      collaborators.first.should == "sferik"
    end

  end

  describe ".remove_collaborator" do

    it "should remove a repository collaborators" do
      stub_post("/api/v2/json/repos/collaborators/sferik/rails_admin/remove/sferik").
        to_return(:body => fixture("v2/collaborators.json"))
      collaborators = @client.remove_collaborator("sferik/rails_admin", "sferik")
      collaborators.first.should == "sferik"
    end

  end

  describe ".pushable" do

    it "should return all pushable repositories" do
      stub_get("/api/v2/json/repos/pushable").
        to_return(:body => fixture("v2/repositories.json"))
      repositories = @client.pushable
      repositories.first.name.should == "One40Proof"
    end

  end

  describe ".repository_teams" do

    it "should return all repository teams" do
      stub_get("/api/v2/json/repos/show/codeforamerica/open311/teams").
        to_return(:body => fixture("v2/teams.json"))
      teams = @client.repository_teams("codeforamerica/open311")
      teams.first.name.should == "Fellows"
    end

  end

  describe ".contributors" do

    context "with anonymous users" do

      it "should return all repository contributors" do
        stub_get("/api/v2/json/repos/show/sferik/rails_admin/contributors/anon").
          to_return(:body => fixture("v2/contributors.json"))
        contributors = @client.contributors("sferik/rails_admin", true)
        contributors.first.name.should == "Erik Michaels-Ober"
      end

    end

    context "without anonymous users" do

      it "should return all repository contributors" do
        stub_get("/api/v2/json/repos/show/sferik/rails_admin/contributors").
          to_return(:body => fixture("v2/contributors.json"))
        contributors = @client.contributors("sferik/rails_admin")
        contributors.first.name.should == "Erik Michaels-Ober"
      end

    end

  end

  describe ".watchers" do

    it "should return all repository watchers" do
      stub_get("/api/v2/json/repos/show/sferik/rails_admin/watchers").
        to_return(:body => fixture("v2/watchers.json"))
      watchers = @client.watchers("sferik/rails_admin")
      watchers.first.should == "sferik"
    end

  end

  describe ".network" do

    it "should return a repository's network" do
      stub_get("/api/v2/json/repos/show/sferik/rails_admin/network").
        to_return(:body => fixture("v2/network.json"))
      network = @client.network("sferik/rails_admin")
      network.first.owner.should == "sferik"
    end

  end

  describe ".languages" do

    it "should return a repository's languages" do
      stub_get("/api/v2/json/repos/show/sferik/rails_admin/languages").
        to_return(:body => fixture("v2/languages.json"))
      languages = @client.languages("sferik/rails_admin")
      languages["Ruby"].should == 205046
    end

  end

  describe ".tags" do

    it "should return a repository's tags" do
      stub_get("/api/v2/json/repos/show/pengwynn/octokit/tags").
        to_return(:body => fixture("v2/tags.json"))
      tags = @client.tags("pengwynn/octokit")
      tags["v0.0.1"].should == "0d7a03f2035ecd74e4d6eb9be58865c2a688ee55"
    end

  end

  describe ".branches" do

    it "should return a repository's branches" do
      stub_get("/api/v2/json/repos/show/pengwynn/octokit/branches").
        to_return(:body => fixture("v2/branches.json"))
      branches = @client.branches("pengwynn/octokit")
      branches["master"].should == "4d9a9e9ca183bab1c3d0accf1d53edd85bd6200f"
    end

  end

end
