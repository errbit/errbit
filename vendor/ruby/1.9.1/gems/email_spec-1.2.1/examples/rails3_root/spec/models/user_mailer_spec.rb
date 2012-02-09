require File.dirname(__FILE__) + '/../spec_helper'

# These two example groups are specifying the exact same behavior.  However, the documentation style is different
# and the value that each one provides is different with various trade-offs.  Run these examples with the specdoc 
# formatter to get an idea of how they differ.
# Example of documenting the behaviour explicitly and expressing the intent in the example's sentence.
describe "Signup Email" do
  include EmailSpec::Helpers
  include EmailSpec::Matchers
  include ::Rails.application.routes.url_helpers

  subject { UserMailer.signup("jojo@yahoo.com", "Jojo Binks") }
  
  it "should be delivered to the email passed in" do
    should deliver_to("jojo@yahoo.com")
  end
  
  it "should contain the user's name in the mail body" do
    should have_body_text(/Jojo Binks/)
  end

  it "should contain a link to the confirmation page" do
    should have_body_text(/#{confirm_account_url(:host => 'example.com')}/)
  end
  
  it { should have_subject(/Account confirmation/) }
  
  
end

# In this example group more of the documentation is placed in the context trying to allow for more concise specs.
describe "Signup Email" do
  include EmailSpec::Helpers
  include EmailSpec::Matchers
  include ::Rails.application.routes.url_helpers

  subject { UserMailer.signup("jojo@yahoo.com", "Jojo Binks") }

  it { should have_body_text(/#{confirm_account_url(:host => 'example.com')}/) }
  it { should have_subject(/Account confirmation/) }

  describe "sent with email address of 'jojo@yahoo.com', and users name 'Jojo Binks'" do
    subject { UserMailer.signup("jojo@yahoo.com", "Jojo Binks") }
    it { should deliver_to("jojo@yahoo.com") }
    it { should have_body_text(/Jojo Binks/) }
  end
end
