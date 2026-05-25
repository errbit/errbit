# frozen_string_literal: true

require "rails_helper"

RSpec.describe FormHelper, type: :helper do
  describe "#errors_for" do
    context "when the document has no errors" do
      it "returns nil" do
        document = double(errors: double(any?: false))

        expect(helper.errors_for(document)).to be_nil
      end
    end

    context "when the document has errors" do
      let(:document) do
        double(errors: double(any?: true, full_messages: ["Name can't be blank", "Email is invalid"]))
      end

      it "wraps the messages in a div with the error-messages class" do
        expect(helper.errors_for(document)).to match(%r{<div class="error-messages">})
      end

      it "renders the standard heading" do
        expect(helper.errors_for(document)).to include(
          "<h2>Dang. The following errors are keeping this from being a success.</h2>"
        )
      end

      it "renders each full message as a list item" do
        html = helper.errors_for(document)

        expect(html).to include("<li>Name can&#39;t be blank</li>")
        expect(html).to include("<li>Email is invalid</li>")
      end

      it "returns an html-safe string" do
        expect(helper.errors_for(document)).to be_html_safe
      end
    end

    context "when a message contains HTML" do
      it "escapes the message content" do
        document = double(errors: double(any?: true, full_messages: ["<script>alert(1)</script>"]))

        html = helper.errors_for(document)

        expect(html).not_to include("<script>alert(1)</script>")
        expect(html).to include("&lt;script&gt;alert(1)&lt;/script&gt;")
      end
    end
  end

  describe "#label_for_attr" do
    let(:builder) { double(object_name: "errbit_app") }

    it "concatenates the object_name with the field" do
      expect(helper.label_for_attr(builder, "name")).to eq("errbit_appname")
    end

    it "replaces brackets with underscores and squeezes them" do
      expect(helper.label_for_attr(builder, "[watchers_attributes][0][email]"))
        .to eq("errbit_app_watchers_attributes_0_email_")
    end

    it "squeezes consecutive underscores spanning object_name and field" do
      nested = double(object_name: "errbit_app[watchers_attributes][0]")

      expect(helper.label_for_attr(nested, "[email]")).to eq("errbit_app_watchers_attributes_0_email_")
    end
  end
end
