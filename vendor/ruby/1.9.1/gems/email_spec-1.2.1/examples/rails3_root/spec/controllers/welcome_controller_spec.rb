require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe WelcomeController do

  describe "POST /signup (#signup)" do
    it "should deliver the signup email" do
      lambda {
        post :signup, "Email" => "email@example.com", "Name" => "Jimmy Bean"
      }.should change(ActionMailer::Base.deliveries, :size).by(1)

      last_delivery = ActionMailer::Base.deliveries.last
      last_delivery.to.should include "email@example.com"
      #message is now multipart, make sure both parts include Jimmy Bean
      last_delivery.parts[0].body.to_s.should include "Jimmy Bean"
      last_delivery.parts[1].body.to_s.should include "Jimmy Bean"
    end

  end

end
