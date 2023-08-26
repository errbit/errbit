describe Problem, type: 'model' do
  context 'validations' do
    it 'requires an environment' do
      err = Fabricate.build(:problem, environment: nil)
      expect(err).to_not be_valid
      expect(err.errors[:environment]).to include("can't be blank")
    end
  end

  describe "Fabrication" do
    context "Fabricate(:problem)" do
      it 'should have no comment' do
        expect do
          Fabricate(:problem)
        end.to_not change(Comment, :count)
      end
    end

    context "Fabricate(:problem_with_comments)" do
      it 'should have 3 comments' do
        expect do
          Fabricate(:problem_with_comments)
        end.to change(Comment, :count).by(3)
      end
    end

    context "Fabricate(:problem_with_errs)" do
      it 'should have 3 errs' do
        expect do
          Fabricate(:problem_with_errs)
        end.to change(Err, :count).by(3)
      end
    end
  end

  context '#last_notice_at' do
    it "returns the created_at timestamp of the latest notice" do
      err = Fabricate(:err)
      problem = err.problem
      expect(problem).to_not be_nil

      notice1 = Fabricate(:notice, err: err)
      expect(problem.last_notice_at).to eq notice1.reload.created_at

      notice2 = Fabricate(:notice, err: err)
      expect(problem.last_notice_at).to eq notice2.reload.created_at
    end
  end

  context '#first_notice_at' do
    it "returns the created_at timestamp of the first notice" do
      err = Fabricate(:err)
      problem = err.problem
      expect(problem).to_not be_nil

      notice1 = Fabricate(:notice, err: err)
      expect(problem.first_notice_at.to_i).to be_within(1).of(notice1.created_at.to_i)

      Fabricate(:notice, err: err)
      expect(problem.first_notice_at.to_i).to be_within(1).of(notice1.created_at.to_i)
    end
  end

  context '#message' do
    it "adding a notice caches its message" do
      err = Fabricate(:err)
      problem = err.problem
      expect do
        Fabricate(:notice, err: err, message: 'ERR 1')
      end.to change(problem, :message).from(nil).to('ERR 1')
    end
  end

  context 'being created' do
    context 'when the app has err notifications set to false' do
      it 'should not send an email notification' do
        app = Fabricate(:app_with_watcher, notify_on_errs: false)
        expect(Mailer).to_not receive(:err_notification)
        Fabricate(:problem, app: app)
      end
    end
  end

  context "#resolved?" do
    it "should start out as unresolved" do
      problem = Problem.new
      expect(problem).to_not be_resolved
      expect(problem).to be_unresolved
    end

    it "should be able to be resolved" do
      problem = Fabricate(:problem)
      expect(problem).to_not be_resolved
      problem.resolve!
      expect(problem.reload).to be_resolved
    end
  end

  context "resolve!" do
    it "marks the problem as resolved" do
      problem = Fabricate(:problem)
      expect(problem).to_not be_resolved
      problem.resolve!
      expect(problem).to be_resolved
    end

    it "should record the time when it was resolved" do
      problem = Fabricate(:problem)
      expected_resolved_at = Time.zone.now
      Timecop.freeze(expected_resolved_at) do
        problem.resolve!
      end
      expect(problem.resolved_at.to_s).to eq expected_resolved_at.to_s
    end

    it "should not reset notice count" do
      problem = Fabricate(:problem, notices_count: 1)
      original_notices_count = problem.notices_count
      expect(original_notices_count).to be > 0

      problem.resolve!
      expect(problem.notices_count).to eq original_notices_count
    end

    it "should throw an err if it's not successful" do
      problem = Fabricate(:problem)
      expect(problem).to_not be_resolved
      allow(problem).to receive(:valid?).and_return(false)
      ## update_attributes not test #valid? but #errors.any?
      # https://github.com/mongoid/mongoid/blob/master/lib/mongoid/persistence.rb#L137
      er = ActiveModel::Errors.new(problem)
      er.add(:resolved, :blank)
      allow(problem).to receive(:errors).and_return(er)
      expect(problem).to_not be_valid
      expect do
        problem.resolve!
      end.to raise_error(Mongoid::Errors::Validations)
    end
  end

  context "#unmerge!" do
    it "creates a separate problem for each err" do
      problem1 = Fabricate(:notice).problem
      problem2 = Fabricate(:notice).problem
      merged_problem = Problem.merge!(problem1, problem2)
      expect(merged_problem.errs.length).to eq 2

      expect { merged_problem.unmerge! }.to change(Problem, :count).by(1)
      expect(merged_problem.errs(true).length).to eq 1
    end

    it "runs smoothly for problem without errs" do
      expect { Fabricate(:problem).unmerge! }.not_to raise_error
    end
  end

  context "Scopes" do
    context "resolved" do
      it 'only finds resolved Problems' do
        resolved = Fabricate(:problem, resolved: true)
        unresolved = Fabricate(:problem, resolved: false)
        expect(Problem.resolved.all).to include(resolved)
        expect(Problem.resolved.all).to_not include(unresolved)
      end
    end

    context "unresolved" do
      it 'only finds unresolved Problems' do
        resolved = Fabricate(:problem, resolved: true)
        unresolved = Fabricate(:problem, resolved: false)
        expect(Problem.unresolved.all).to_not include(resolved)
        expect(Problem.unresolved.all).to include(unresolved)
      end
    end

    context "searching" do
      it 'finds the correct record' do
        find = Fabricate(:problem, resolved: false, error_class: 'theErrorclass::other',
                         message: "other", where: 'errorclass', environment: 'development', app_name: 'other')
        dont_find = Fabricate(:problem, resolved: false, error_class: "Batman",
                              message: 'todo', where: 'classerror', environment: 'development', app_name: 'other')
        expect(Problem.search("theErrorClass").unresolved).to include(find)
        expect(Problem.search("theErrorClass").unresolved).to_not include(dont_find)
      end
      it 'find on where message' do
        problem = Fabricate(:problem, where: 'cyril')
        expect(Problem.search('cyril').entries).to eq [problem]
      end
      it 'finds with notice_id as argument' do
        app = Fabricate(:app)
        problem = Fabricate(:problem, app: app)
        err = Fabricate(:err, problem: problem)
        notice = Fabricate(:notice, err: err, message: 'ERR 1')

        problem2 = Fabricate(:problem, where: 'cyril')
        expect(problem2).to_not eq(problem)
        expect(Problem.search(notice.id).entries).to eq [problem]
      end
    end
  end

  context "notice counter cache" do
    before do
      @app = Fabricate(:app)
      @problem = Fabricate(:problem, app: @app)
      @err = Fabricate(:err, problem: @problem)
    end

    it "#notices_count returns 0 by default" do
      expect(@problem.notices_count).to eq 0
    end

    it "adding a notice increases #notices_count by 1" do
      expect do
        Fabricate(:notice, err: @err, message: 'ERR 1')
      end.to change(@problem.reload, :notices_count).from(0).to(1)
    end

    it "removing a notice decreases #notices_count by 1" do
      Fabricate(:notice, err: @err, message: 'ERR 1')
      expect do
        @err.notices.first.destroy
        @problem.reload
      end.to change(@problem, :notices_count).from(1).to(0)
    end
  end

  context "sparklines-related methods" do
    before do
      @app = Fabricate(:app)
      @problem = Fabricate(:problem, app: @app)
      @err = Fabricate(:err, problem: @problem)
    end

    it "gets correct notice counts when grouping by day" do
      now = Time.current
      two_weeks_ago = 13.days.ago
      Fabricate(:notice, err: @err, message: 'ERR 1')
      Fabricate(:notice, err: @err, message: 'ERR 2', created_at: 3.days.ago)
      Fabricate(:notice, err: @err, message: 'ERR 3', created_at: 3.days.ago)
      three_days_ago_yday = (now - 3.days).yday
      three_days_ago = @problem.grouped_notice_counts(two_weeks_ago, 'day').detect { |grouping| grouping['_id']['day'] == three_days_ago_yday }
      expect(three_days_ago['count']).to eq(2)
      count_by_day_for_last_two_weeks = @problem.zero_filled_grouped_noticed_counts(two_weeks_ago, 'day').map { |h| h.values.first }
      expect(count_by_day_for_last_two_weeks.size).to eq(14)
      expect(count_by_day_for_last_two_weeks).to eq([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 1])
    end

    it "gets correct notice counts when grouping by hour" do
      twenty_four_hours_ago = 23.hours.ago
      Fabricate(:notice, err: @err, message: 'ERR 1')
      Fabricate(:notice, err: @err, message: 'ERR 2', created_at: 3.hours.ago)
      Fabricate(:notice, err: @err, message: 'ERR 3', created_at: 3.hours.ago)
      count_by_hour_for_last_24_hours = @problem.zero_filled_grouped_noticed_counts(twenty_four_hours_ago, 'hour').map { |h| h.values.first }
      expect(count_by_hour_for_last_24_hours.size).to eq(24)
      expect(count_by_hour_for_last_24_hours).to eq(([0] * 20) + [2, 0, 0, 1])
    end

    it "gets correct relative percentages when grouping by hour" do
      two_weeks_ago = 13.days.ago
      Fabricate(:notice, err: @err, message: 'ERR 1')
      Fabricate(:notice, err: @err, message: 'ERR 2', created_at: 3.days.ago)
      Fabricate(:notice, err: @err, message: 'ERR 3', created_at: 3.days.ago)
      relative_percentages = @problem.grouped_notice_count_relative_percentages(two_weeks_ago, 'day')
      expect(relative_percentages).to eq(([0] * 10) + [100, 0, 0, 50])
    end

    it "gets correct relative percentages when grouping by hour" do
      twenty_four_hours_ago = 23.hours.ago
      Fabricate(:notice, err: @err, message: 'ERR 1')
      Fabricate(:notice, err: @err, message: 'ERR 2', created_at: 3.hours.ago)
      Fabricate(:notice, err: @err, message: 'ERR 3', created_at: 3.hours.ago)
      relative_percentages = @problem.grouped_notice_count_relative_percentages(twenty_four_hours_ago, 'hour')
      expect(relative_percentages).to eq(([0] * 20) + [100, 0, 0, 50])
    end

    it "gets correct relative percentages when all zeros for data" do
      two_weeks_ago = 13.days.ago
      relative_percentages = @problem.grouped_notice_count_relative_percentages(two_weeks_ago, 'day')
      expect(relative_percentages).to eq(([0] * 14))
    end
  end

  context "filtered" do
    before do
      @app1 = Fabricate(:app)
      @problem1 = Fabricate(:problem, app: @app1)

      @app2 = Fabricate(:app)
      @problem2 = Fabricate(:problem, app: @app2)

      @app3 = Fabricate(:app)
      @app3.update_attribute(:name, 'app3')

      @problem3 = Fabricate(:problem, app: @app3)
    end

    it "#filtered returns problems but excludes those attached to the specified apps" do
      expect(Problem.filtered("-app:'#{@app1.name}'")).to include(@problem2)
      expect(Problem.filtered("-app:'#{@app1.name}'")).to_not include(@problem1)

      filtered_results_with_two_exclusions = Problem.filtered("-app:'#{@app1.name}' -app:app3")
      expect(filtered_results_with_two_exclusions).to_not include(@problem1)
      expect(filtered_results_with_two_exclusions).to include(@problem2)
      expect(filtered_results_with_two_exclusions).to_not include(@problem3)
    end

    it "#filtered does not explode if given a nil filter" do
      filtered_results = Problem.filtered(nil)
      expect(filtered_results).to include(@problem1)
      expect(filtered_results).to include(@problem2)
      expect(filtered_results).to include(@problem3)
    end

    it "#filtered does nothing for unimplemented filter types" do
      filtered_results = Problem.filtered("filterthatdoesnotexist:hotapp")
      expect(filtered_results).to include(@problem1)
      expect(filtered_results).to include(@problem2)
      expect(filtered_results).to include(@problem3)
    end
  end

  context "#app_name" do
    let!(:app) { Fabricate(:app) }
    let!(:problem) { Fabricate(:problem, app: app) }

    before { app.reload }

    it "is set when a problem is created" do
      assert_equal app.name, problem.app_name
    end

    it "is updated when an app is updated" do
      expect do
        app.update_attributes!(name: "Bar App")
        problem.reload
      end.to change(problem, :app_name).to("Bar App")
    end
  end

  context "notice messages cache" do
    before do
      @app = Fabricate(:app)
      @problem = Fabricate(:problem, app: @app)
      @err = Fabricate(:err, problem: @problem)
    end

    it "#messages should be empty by default" do
      expect(@problem.messages).to eq({})
    end

    it "removing a notice removes string from #messages" do
      Fabricate(:notice, err: @err, message: 'ERR 1')
      expect do
        @err.notices.first.destroy
        @problem.reload
      end.to change(@problem, :messages).from(Digest::MD5.hexdigest('ERR 1') => { 'value' => 'ERR 1', 'count' => 1 }).to({})
    end

    it "removing a notice from the problem with broken counter should not raise an error" do
      Fabricate(:notice, err: @err, message: 'ERR 1')
      @problem.messages = {}
      @problem.save!
      expect { @err.notices.first.destroy }.not_to raise_error
    end
  end

  context "notice hosts cache" do
    before do
      @app = Fabricate(:app)
      @problem = Fabricate(:problem, app: @app)
      @err = Fabricate(:err, problem: @problem)
    end

    it "#hosts should be empty by default" do
      expect(@problem.hosts).to eq({})
    end

    it "removing a notice removes string from #hosts" do
      Fabricate(:notice, err: @err, request: { 'url' => "http://example.com/resource/12" })
      expect do
        @err.notices.first.destroy
        @problem.reload
      end.to change(@problem, :hosts).from(Digest::MD5.hexdigest('example.com') => { 'value' => 'example.com', 'count' => 1 }).to({})
    end
  end

  context "notice user_agents cache" do
    before do
      @app = Fabricate(:app)
      @problem = Fabricate(:problem, app: @app)
      @err = Fabricate(:err, problem: @problem)
    end

    it "#user_agents should be empty by default" do
      expect(@problem.user_agents).to eq({})
    end

    it "removing a notice removes string from #user_agents" do
      Fabricate(
        :notice,
        err:     @err,
        request: {
          'cgi-data' => {
            'HTTP_USER_AGENT' => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_7; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.648.204 Safari/534.16'
          }
        }
      )
      expect do
        @err.notices.first.destroy
        @problem.reload
      end.to change(@problem, :user_agents).
        from(
          Digest::MD5.hexdigest('Chrome 10.0.648.204 (OS X 10.6.7)') => {
            'value' => 'Chrome 10.0.648.204 (OS X 10.6.7)', 'count' => 1 }
        ).to({})
    end
  end

  context "comment counter cache" do
    before do
      @app = Fabricate(:app)
      @problem = Fabricate(:problem, app: @app)
    end

    it "#comments_count returns 0 by default" do
      expect(@problem.comments_count).to eq 0
    end

    it "adding a comment increases #comments_count by 1" do
      expect do
        Fabricate(:comment, err: @problem)
      end.to change(@problem, :comments_count).from(0).to(1)
    end

    it "removing a comment decreases #comments_count by 1" do
      Fabricate(:comment, err: @problem)
      expect do
        @problem.reload.comments.first.destroy
        @problem.reload
      end.to change(@problem, :comments_count).from(1).to(0)
    end
  end

  describe "#issue_type" do
    context "without issue_type fill in Problem" do
      let(:problem) do
        Problem.new(app: app)
      end

      let(:app) do
        App.new(issue_tracker: issue_tracker)
      end

      context "without issue_tracker associate to app" do
        let(:issue_tracker) do
          nil
        end
        it 'return nil' do
          expect(problem.issue_type).to be_nil
        end
      end

      context "with issue_tracker valid associate to app" do
        let(:issue_tracker) do
          Fabricate(:issue_tracker).tap do |t|
            t.instance_variable_set(:@tracker, ErrbitPlugin::MockIssueTracker.new(t.options))
          end
        end

        it 'return the issue_tracker label' do
          expect(problem.issue_type).to eql 'mock'
        end
      end

      context "with issue_tracker not valid associate to app" do
        let(:issue_tracker) do
          IssueTracker.new(type_tracker: 'fake')
        end

        it 'return nil' do
          expect(problem.issue_type).to be_nil
        end
      end
    end

    context "with issue_type fill in Problem" do
      it 'return the value associate' do
        expect(Problem.new(issue_type: 'foo').issue_type).to eql 'foo'
      end
    end
  end

  describe '#recache' do
    let(:problem) { Fabricate(:problem_with_errs) }
    let(:first_errs) { problem.errs }
    let!(:notice) { Fabricate(:notice, err: first_errs.first) }

    before do
      problem.update_attribute(:notices_count, 0)
    end

    it 'update the notice_count' do
      expect do
        problem.recache
      end.to change {
        problem.notices_count
      }.from(0).to(1)
    end

    context "with only one notice" do
      before do
        problem.update_attributes!(messages: {})
        problem.recache
      end

      it 'update information about this notice' do
        expect(problem.message).to eq notice.message
        expect(problem.where).to eq notice.where
      end

      it 'update first_notice_at' do
        expect(problem.first_notice_at).to eq notice.reload.created_at
      end

      it 'update last_notice_at' do
        expect(problem.last_notice_at).to eq notice.reload.created_at
      end

      it 'update stats messages' do
        expect(problem.messages).to eq(
          Digest::MD5.hexdigest(notice.message) => { 'value' => notice.message, 'count' => 1 }
        )
      end

      it 'update stats hosts' do
        expect(problem.hosts).to eq(
          Digest::MD5.hexdigest(notice.host) => { 'value' => notice.host, 'count' => 1 }
        )
      end

      it 'update stats user_agents' do
        expect(problem.user_agents).to eq(
          Digest::MD5.hexdigest(notice.user_agent_string) => { 'value' => notice.user_agent_string, 'count' => 1 }
        )
      end
    end

    context "with several notices" do
      let!(:notice_2) { Fabricate(:notice, err: first_errs.first) }
      let!(:notice_3) { Fabricate(:notice, err: first_errs.first) }
      before do
        problem.update_attributes!(messages: {})
        problem.recache
      end

      it 'update information about this notice' do
        expect(problem.message).to eq notice.message
        expect(problem.where).to eq notice.where
      end

      it 'update first_notice_at' do
        expect(problem.first_notice_at.to_i).to be_within(2).of(notice.created_at.to_i)
      end

      it 'update last_notice_at' do
        expect(problem.last_notice_at.to_i).to be_within(2).of(notice.created_at.to_i)
      end

      it 'update stats messages' do
        expect(problem.messages).to eq(Digest::MD5.hexdigest(notice.message) => { 'value' => notice.message, 'count' => 3 })
      end

      it 'update stats hosts' do
        expect(problem.hosts).to eq(Digest::MD5.hexdigest(notice.host) => { 'value' => notice.host, 'count' => 3 })
      end

      it 'update stats user_agents' do
        expect(problem.user_agents).to eq(Digest::MD5.hexdigest(notice.user_agent_string) => { 'value' => notice.user_agent_string, 'count' => 3 })
      end
    end
  end

  context "#url" do
    subject { Fabricate(:problem) }

    it "uses the configured protocol" do
      allow(Errbit::Config).to receive(:protocol).and_return("https")

      expect(subject.url).to eq "https://errbit.example.com/apps/#{subject.app.id}/problems/#{subject.id}"
    end

    it "uses the configured host" do
      allow(Errbit::Config).to receive(:host).and_return("memyselfandi.com")

      expect(subject.url).to eq "http://memyselfandi.com/apps/#{subject.app.id}/problems/#{subject.id}"
    end

    it "uses the configured port" do
      allow(Errbit::Config).to receive(:port).and_return(8123)

      expect(subject.url).to eq "http://errbit.example.com:8123/apps/#{subject.app.id}/problems/#{subject.id}"
    end
  end
end
