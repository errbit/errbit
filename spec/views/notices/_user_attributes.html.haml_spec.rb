require 'spec_helper'

describe "notices/_user_attributes.html.haml" do
  describe 'autolink' do
    let(:notice) do
      user_attributes = { 'foo' => {'bar' => 'http://example.com'} }
      Fabricate(:notice, :user_attributes => user_attributes)
    end

    it "renders table with user attributes" do
      assign :app, notice.err.app

      render "notices/user_attributes", :user => notice.user_attributes
      expect(rendered).to have_link('http://example.com')
    end
  end
end

