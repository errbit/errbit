require "spec_helper"

describe Fingerprint do
  let(:app_id) { "<app.id>" }

  context "for two notices" do
    let(:backtrace1) { backtrace_with_no_in_app_lines }
    let(:notice1) { Fabricate.build(:notice, backtrace: backtrace1) }
    let(:notice2) { Fabricate.build(:notice, backtrace: backtrace2) }
    let(:fingerprint1) { Fingerprint.generate(notice1, app_id) }
    let(:fingerprint2) { Fingerprint.generate(notice2, app_id) }

    context "with the same backtrace" do
      let(:backtrace2) { backtrace1 }

      context "and message" do
        it "should be the same" do
          expect(fingerprint1).to eq(fingerprint2)
        end

        context "despite having different environments" do
          before do
            notice1.stub(:environment_name) { "development" }
            notice2.stub(:environment_name) { "production" }
          end

          it "should be the same" do
            expect(fingerprint1).to eq(fingerprint2)
          end
        end
      end

      context "and messages that differ only in memory addresses" do
        before do
          notice1.message = "NoMethodError: undefined method `foo' for #<ActiveSupport::HashWithIndifferentAccess:0x007f6bfe3287e8>"
          notice2.message = "NoMethodError: undefined method `foo' for #<ActiveSupport::HashWithIndifferentAccess:0x007f6bfd9f5338>"
        end

        it "should be the same" do
          expect(fingerprint1).to eq(fingerprint2)
        end
      end

      context "but different messages" do
        before do
          notice1.message = "NoMethodError: undefined method `bar' for #<ActiveSupport::HashWithIndifferentAccess:0x007f6bfe3287e8>"
          notice2.message = "NoMethodError: undefined method `bar' for nil:NilClass"
        end

        it "should be different" do
          expect(fingerprint1).not_to eq(fingerprint2)
        end
      end
    end

    context "with different backtraces" do
      let(:backtrace2) {
        backtrace = backtrace1
        backtrace.lines.last.number = 401
        backtrace.send(:generate_fingerprint)
        backtrace.save
        backtrace
      }

      it "should be different" do
        expect(fingerprint1).not_to eq(fingerprint2)
      end
    end

    context "with backtraces where the in-app trace and all method calls above it are the same" do
      let(:backtrace1) { backtrace_with_in_app_lines1 }
      let(:backtrace2) { backtrace_with_in_app_lines2 }

      it "should be the same" do
        expect(fingerprint1).to eq(fingerprint2)
      end
    end
  end



  describe "#normalized_message" do
    subject { Fingerprint.new(double("notice", message: message), app_id).normalized_message }

    context "given objects with memory addresses" do
      let(:message) { "NoMethodError: undefined method `foo' for #<ActiveSupport::HashWithIndifferentAccess:0x007f6bfe3287e8> #<Object:0x007fa2b33d9458>" }

      it "removes the memory addresses from all object strings" do
        should eq "NoMethodError: undefined method `foo' for #<ActiveSupport::HashWithIndifferentAccess> #<Object>"
      end
    end
  end

private

  # Backtrace for AirbrakeTestingException on Rails 4.0.4 and Ruby 2.0.0
  def backtrace_with_no_in_app_lines
    Backtrace.create(:raw => [
      line("activesupport-4.0.4/lib/active_support/callbacks.rb",   377, "_run__FRAGMENT__process_action__callbacks"),
      line("activesupport-4.0.4/lib/active_support/callbacks.rb",    80, "run_callbacks"),
      line("actionpack-4.0.4/lib/abstract_controller/callbacks.r",   17, "process_action"),
      line("actionpack-4.0.4/lib/action_controller/metal/rescue.rb", 29, "process_action"),
      # ...
      line("rake-10.2.2/lib/rake/application.rb",                    75, "run"),
      line("rake-10.2.2/bin/rake",                                   33, "<top (required)>"),
      line("/opt/boxen/rbenv/versions/2.0.0-p353/bin/rake",          23, "load"),
      line("/opt/boxen/rbenv/versions/2.0.0-p353/bin/rake",          23, "<main>")
    ])
  end

  def backtrace_with_in_app_lines1
    Backtrace.create(:raw => [
      line("[GEM_ROOT]/gems/activerecord-4.0.3/lib/active_record/relation/query_methods.rb", 1026),
      line("[GEM_ROOT]/gems/activerecord-4.0.3/lib/active_record/relation/query_methods.rb", 1024),
      line("[GEM_ROOT]/gems/activerecord-4.0.3/lib/active_record/relation/query_methods.rb", 1024),
      line("[GEM_ROOT]/gems/activerecord-4.0.3/lib/active_record/relation/query_methods.rb",  281),
      line("[GEM_ROOT]/gems/activerecord-4.0.3/lib/active_record/relation/query_methods.rb",  276),
      line("[PROJECT_ROOT]/app/models/household.rb",                                           48),
      line("[GEM_ROOT]/gems/activerecord-4.0.3/lib/active_record/relation/delegation.rb",      60),
      line("[GEM_ROOT]/gems/activerecord-4.0.3/lib/active_record/relation.rb",                270),
      line("[GEM_ROOT]/gems/activerecord-4.0.3/lib/active_record/relation/delegation.rb",      60),
      line("[PROJECT_ROOT]/app/models/household.rb",                                           71)
    ])
  end

  def backtrace_with_in_app_lines2
    Backtrace.create(:raw => [
      line("[GEM_ROOT]/gems/activerecord-4.0.3/lib/active_record/relation/query_methods.rb", 1026),
      line("[GEM_ROOT]/gems/activerecord-4.0.3/lib/active_record/relation/query_methods.rb", 1024),
      line("[GEM_ROOT]/gems/activerecord-4.0.3/lib/active_record/relation/query_methods.rb", 1024),
      line("[GEM_ROOT]/gems/activerecord-4.0.3/lib/active_record/relation/query_methods.rb",  281),
      line("[GEM_ROOT]/gems/activerecord-4.0.3/lib/active_record/relation/query_methods.rb",  276),
      line("[PROJECT_ROOT]/app/models/household.rb",                                           48),
      line("[PROJECT_ROOT]/app/models/household.rb",                                           71)
    ])
  end

  def line(file, line_number, method="<method>")
    {"number" => line_number.to_s, "file" => file, "method" => method}
  end

end
