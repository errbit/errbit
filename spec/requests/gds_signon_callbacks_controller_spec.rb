require 'spec_helper'

describe "GDS Signon callbacks" do
  describe "User update" do
    before :each do
      @user = Fabricate(:user, :uid => "5678", :name => "Original Name", :email => "original@example.com")
    end

    context "with an authorised user" do
      before :each do
        stub_signon_user("12345678", %w(signin user_update_permission))
      end

      it "should update the target user's details" do
        post_details = signon_user_hash(:uid => "5678", :name => "Updated Name", :email => "updated@example.com", :perms => ["signin", "editor"])
        put "/auth/gds/api/users/5678", post_details.to_json, {'CONTENT_TYPE' => 'application/json', 'HTTP_AUTHORIZATION' => "Bearer 12345678"}

        expect(response.code.to_i).to eq(200)
        @user.reload
        expect(@user.name).to eq("Updated Name")
        expect(@user.email).to eq("updated@example.com")
        expect(@user.permissions).to eq(%w(signin editor))
      end

      it "should respond with success for a non-existent user" do
        put "/auth/gds/api/users/321", signon_user_hash(:uid => "321").to_json, {'CONTENT_TYPE' => 'application/json', 'HTTP_AUTHORIZATION' => "Bearer 12345678"}

        expect(response.code.to_i).to eq(200)
      end
    end

    context "without an authorisation user" do

      it "should be unauthorised with no bearer token" do
        put "/auth/gds/api/users/5678", signon_user_hash(:uid => "5678").to_json, {'CONTENT_TYPE' => 'application/json'}

        expect(response.code.to_i).to eq(401)
        @user.reload
        expect(@user.email).to eq("original@example.com")
      end

      it "should be unauthorised with an invalid bearer token" do
        stub_signon_invalid_token("12345678")

        put "/auth/gds/api/users/5678", signon_user_hash(:uid => "5678").to_json, {'CONTENT_TYPE' => 'application/json', 'HTTP_AUTHORIZATION' => "Bearer 12345678"}

        expect(response.code.to_i).to eq(401)
        @user.reload
        expect(@user.email).to eq("original@example.com")
      end

      it "should be unauthorised for a user without the 'user_update_permission' permission" do
        stub_signon_user("12345678", %w(signin))

        put "/auth/gds/api/users/5678", signon_user_hash(:uid => "5678").to_json, {'CONTENT_TYPE' => 'application/json', 'HTTP_AUTHORIZATION' => "Bearer 12345678"}

        expect(response.code.to_i).to eq(401)
        @user.reload
        expect(@user.email).to eq("original@example.com")
      end
    end
  end

  describe "User reauth" do
    before :each do
      @user = Fabricate(:user, :uid => "5678")
    end

    context "with an authorised user" do
      before :each do
        stub_signon_user("12345678", %w(signin user_update_permission))
      end

      it "should set remotely_signed_out on the target user" do
        post "/auth/gds/api/users/5678/reauth", "{}", {'CONTENT_TYPE' => 'application/json', 'HTTP_AUTHORIZATION' => "Bearer 12345678"}

        expect(response.code.to_i).to eq(200)
        @user.reload
        expect(@user).to be_remotely_signed_out
      end

      it "should respond with success for a non-existent user" do
        post "/auth/gds/api/users/1234/reauth", "{}", {'CONTENT_TYPE' => 'application/json', 'HTTP_AUTHORIZATION' => "Bearer 12345678"}

        expect(response.code.to_i).to eq(200)

        @user.reload
        expect(@user).not_to be_remotely_signed_out
      end
    end

    context "without an authorised user" do

      it "should be unauthorised with no bearer token" do
        post "/auth/gds/api/users/5678/reauth", "{}", {'CONTENT_TYPE' => 'application/json'}

        expect(response.code.to_i).to eq(401)
        @user.reload
        expect(@user).not_to be_remotely_signed_out
      end

      it "should be unauthorised with an invalid bearer token" do
        stub_signon_invalid_token("12345678")

        post "/auth/gds/api/users/5678/reauth", "{}", {'CONTENT_TYPE' => 'application/json', 'HTTP_AUTHORIZATION' => "Bearer 12345678"}

        expect(response.code.to_i).to eq(401)
        @user.reload
        expect(@user).not_to be_remotely_signed_out
      end

      it "should be unauthorised for a user without the 'user_update_permission' permission" do
        stub_signon_user("12345678", %w(signin))

        post "/auth/gds/api/users/5678/reauth", "{}", {'CONTENT_TYPE' => 'application/json', 'HTTP_AUTHORIZATION' => "Bearer 12345678"}

        expect(response.code.to_i).to eq(401)
        @user.reload
        expect(@user).not_to be_remotely_signed_out
      end
    end

  end

  def stub_signon_user(token, perms)
    WebMock.stub_request(:get, "#{GDS::SSO::Config.oauth_root_url}/user.json?client_id=#{CGI.escape(GDS::SSO::Config.oauth_id)}").
      with(:headers => {"Authorization" => "Bearer #{token}"}).
      to_return(:status => 200, :body => signon_user_hash(:perms => perms).to_json, :headers => {"Content-Type" => "application/json"})
  end

  def stub_signon_invalid_token(token)
    WebMock.stub_request(:get, "#{GDS::SSO::Config.oauth_root_url}/user.json?client_id=#{CGI.escape(GDS::SSO::Config.oauth_id)}").
      with(:headers => {"Authorization" => "Bearer #{token}"}).
      to_return(:status => 401)
  end

  def signon_user_hash(details)
    {
      "user" => {
        "uid" => details[:uid] || Devise.friendly_token,
        "name" => details[:name] || "Callback User",
        "email" => details[:email] || "callback@example.com",
        "permissions" => details[:perms] || [],
        "organisation_slug" => "something",
      },
    }
  end

end
