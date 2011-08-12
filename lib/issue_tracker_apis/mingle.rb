module Mingle
  class Card < ActiveResource::Base
    # site template ~> "https://username:password@mingle.example.com/api/v1/projects/:project_id/"
  end
  def self.set_site(site)
    # ActiveResource seems to clone and freeze the @site variable
    # after the first use. It seems that the only way to change @site
    # is to drop the subclass, and then reload it.
    Mingle.send(:remove_const, :Card)
    load File.join(Rails.root,'lib','issue_tracker_apis','mingle.rb')
    Mingle::Card.site = site
  end
end

