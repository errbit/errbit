require 'spec_helper'

describe BacktraceLineHelper do
  describe "in app lines" do
    let(:notice) do
      Fabricate(:notice, :backtrace =>
        Fabricate(:backtrace, :lines => [
          Fabricate(:backtrace_line, :file => "[PROJECT_ROOT]/path/to/asset.rb")
        ])
      )
    end
    let(:line) { notice.backtrace.lines.first }
    let(:app) { line.app }

    describe '#link_to_source_file' do
      describe "when no repo is configured" do
        it 'still returns text for in app file and line number' do
          result = link_to_source_file(line, notice) { haml_concat "link text" }
          result.strip.should == 'link text'
        end
      end

      describe "when a GitHub repo is configured" do
        before do
          app.github_repo = "errbit/example"
        end
        
        it "returns a link to GitHub" do
          result = link_to_source_file(line, notice) { haml_concat "link text" }
          result.should include("https://github.com/errbit/example/blob/master/path/to/asset.rb#L#{line.number}")
        end
        
        describe "and GIT_COMMIT is present in the environment" do
          let(:sha) { "1234567890" }
          let!(:notice) do
            Fabricate(:notice, :request => {"cgi-data" => {"GIT_COMMIT" => sha}}, :backtrace =>
              Fabricate(:backtrace, :lines => [
                Fabricate(:backtrace_line, :file => "[PROJECT_ROOT]/path/to/asset.rb")
              ])
            )
          end
          
          it 'returns a link to a file on GitHub at a specific commit' do
            result = link_to_source_file(line, notice) { haml_concat "link text" }
            result.should include("https://github.com/errbit/example/blob/#{sha}/path/to/asset.rb#L#{line.number}")
          end
        end
      end
    end
  end
end
