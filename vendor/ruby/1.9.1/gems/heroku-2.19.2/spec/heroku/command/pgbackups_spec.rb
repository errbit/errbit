require "spec_helper"
require "heroku/command/pgbackups"

module Heroku::Command
  describe Pgbackups do
    before do
      @pgbackups = prepare_command(Pgbackups)
      @pgbackups.stub!(:config_vars).and_return({
        "PGBACKUPS_URL" => "https://ip:password@pgbackups.heroku.com/client"
      })
      @pgbackups.heroku.stub!(:info).and_return({})
    end

    it "requests a pgbackups transfer list for the index command" do
      fake_client = mock("pgbackups_client")
      fake_client.should_receive(:get_transfers).and_return([])
      @pgbackups.stub!(:no_backups_error!)
      @pgbackups.should_receive(:pgbackup_client).with.and_return(fake_client)

      @pgbackups.index
    end

    describe "single backup" do
      it "gets the url for the latest backup if nothing is specified" do
        latest_backup_url= "http://latest/backup.dump"
        fake_client = mock("pgbackups_client")
        fake_client.should_receive(:get_latest_backup).and_return({'public_url' => latest_backup_url })
        @pgbackups.should_receive(:pgbackup_client).and_return(fake_client)
        @pgbackups.should_receive(:display).with('"'+latest_backup_url+'"')

        @pgbackups.url
      end

      it "gets the url for the named backup if a name is specified" do
        backup_name = "b001"
        named_url = "http://latest/backup.dump"
        @pgbackups.stub!(:args).and_return([backup_name])

        fake_client = mock("pgbackups_client")
        fake_client.should_receive(:get_backup).with(backup_name).and_return({'public_url' => named_url })
        @pgbackups.should_receive(:pgbackup_client).and_return(fake_client)

        @pgbackups.should_receive(:display).with('"'+named_url+'"')

        @pgbackups.url
      end

      it "should capture a backup when requested" do
        from_url = "postgres://from/bar"
        from_name = "FROM_NAME"
        backup_obj = {'to_url' => "s3://bucket/userid/b001.dump"}

        @pgbackups.stub!(:resolve_db).and_return( {:url => from_url, :name => from_name} )
        @pgbackups.stub!(:poll_transfer!).with(backup_obj).and_return(backup_obj)

        fake_client = mock("pgbackups_client")
        fake_client.should_receive(:create_transfer).with(from_url, from_name, nil, "BACKUP", {:expire => nil}).and_return(backup_obj)
        @pgbackups.should_receive(:pgbackup_client).and_return(fake_client)

        @pgbackups.capture
      end

      it "should send expiration flag to client if specified on args" do
        from_url = "postgres://from/bar"
        from_name = "FROM_NAME"
        backup_obj = {'to_url' => "s3://bucket/userid/b001.dump"}

        @pgbackups.stub!(:resolve_db).and_return( {:url => from_url, :name => from_name} )
        @pgbackups.stub!(:poll_transfer!).with(backup_obj).and_return(backup_obj)
        @pgbackups.stub!(:options).and_return(:expire => true)

        fake_client = mock("pgbackups_client")
        fake_client.should_receive(:create_transfer).with(from_url, from_name, nil, "BACKUP", {:expire => true}).and_return(backup_obj)
        @pgbackups.should_receive(:pgbackup_client).and_return(fake_client)

        @pgbackups.capture
      end

      it "destroys no backup without a name" do
        @pgbackups.stub!(:args).and_return([])

        fake_client = mock("pgbackups_client")
        fake_client.should_not_receive(:delete_backup)
        @pgbackups.should_not_receive(:pgbackup_client).and_return(fake_client)

        @pgbackups.stub!(:abort).and_raise(SystemExit)

        lambda { @pgbackups.destroy }.should raise_error SystemExit
      end

      it "destroys a backup on request if confirmed" do
        name = "b001"
        @pgbackups.stub!(:args).and_return([name])

        fake_client = mock("pgbackups_client")
        fake_client.should_receive(:get_backup).with(name).and_return({})
        fake_client.should_receive(:delete_backup).with(name).and_return({})
        @pgbackups.should_receive(:pgbackup_client).and_return(fake_client, fake_client)

        @pgbackups.destroy
      end

      it "aborts if no database addon is present" do
        @pgbackups.should_receive(:abort).and_raise(SystemExit)
        lambda { @pgbackups.capture }.should raise_error SystemExit
      end

      context "on errors" do
        def stub_failed_capture(log)
          backup_obj = {
            "error_at" => Time.now.to_s,
            "log" => log,
            'to_url' => 'postgres://from/bar'
          }
          @pgbackups.stub!(:transfer!).and_return(backup_obj)
          @pgbackups.stub!(:poll_transfer!).with(backup_obj).and_return(backup_obj)
        end

        before(:each) do
          @pgbackups.stub!(:resolve_db).and_return({})
        end

        it 'aborts on a generic error' do
          stub_failed_capture "something generic"
          @pgbackups.should_receive(:error).with("An error occurred and your backup did not finish.")
          @pgbackups.capture
        end

        it 'aborts and informs when the database isnt up yet' do
          stub_failed_capture 'could not translate host name "ec2-42-42-42-42.compute-1.amazonaws.com" to address: Name or service not known'
          @pgbackups.should_receive(:error) do |message|
            message.should =~ /The database is not yet online/
            message.should =~ /Please try again/
          end
          @pgbackups.capture
        end

        it 'aborts and informs when the credentials are incorrect' do
          stub_failed_capture 'psql: FATAL:  database "randomname" does not exist'
          @pgbackups.should_receive(:error) do |message|
            message.should =~ /The database credentials are incorrect/
          end
          @pgbackups.capture
        end
      end
    end

    context "restore" do
      before do
        from_url = "postgres://fromhost/database"
        from_name = "FROM_NAME"
        @pgbackups.stub!(:resolve_db).and_return({:name => from_name, :url => from_url})

        @pgbackups_client = mock("pgbackups_client")
        @pgbackups.stub!(:pgbackup_client).and_return(@pgbackups_client)
      end

      it "should receive a confirm_command on restore" do
        @pgbackups_client.stub!(:get_latest_backup).and_return({"to_url" => "s3://bucket/user/bXXX.dump"})

        @pgbackups.should_receive(:confirm_command).and_return(false)
        @pgbackups_client.should_not_receive(:transfer!)

        @pgbackups.restore
      end

      it "aborts if no database addon is present" do
        @pgbackups.should_receive(:resolve_db).and_raise(SystemExit)
        lambda { @pgbackups.restore }.should raise_error(SystemExit)
      end

      context "for commands which perform restores" do
        before do
          @backup_obj = {
            "to_name" => "TO_NAME",
            "to_url" => "s3://bucket/userid/bXXX.dump",
            "from_url" => "FROM_NAME",
            "from_name" => "postgres://databasehost/dbname"
          }

          @pgbackups.stub!(:confirm_command).and_return(true)
          @pgbackups_client.should_receive(:create_transfer).and_return(@backup_obj)
          @pgbackups.stub!(:poll_transfer!).and_return(@backup_obj)
        end

        it "should default to the latest backup" do
          @pgbackups.stub(:args).and_return([])
          @pgbackups_client.should_receive(:get_latest_backup).and_return(@backup_obj)
          @pgbackups.restore
        end

        it "should restore the named backup" do
          name = "backupname"
          args = ['db_name_gets_shifted_out_in_resove_db', name]
          @pgbackups.stub(:args).and_return(args)
          @pgbackups.stub(:resolve_db) { args.shift; {:name => 'name', :url => 'url'} }
          @pgbackups_client.should_receive(:get_backup).with(name).and_return(@backup_obj)
          @pgbackups.restore
        end

        it "should handle external restores" do
          args = ['db_name_gets_shifted_out_in_resove_db', "http://external/file.dump"]
          @pgbackups.stub(:args).and_return(args)
          @pgbackups.stub(:resolve_db) { args.shift; {:name => 'name', :url => 'url'} }
          @pgbackups_client.should_not_receive(:get_backup)
          @pgbackups_client.should_not_receive(:get_latest_backup)
          @pgbackups.restore
        end
      end

      context "on errors" do
        before(:each) do
          @pgbackups_client.stub!(:get_latest_backup).and_return({"to_url" => "s3://bucket/user/bXXX.dump"})
          @pgbackups.stub!(:confirm_command).and_return(true)
        end

        def stub_error_backup_with_log(log)
          @backup_obj = {
            "error_at" => Time.now.to_s,
            "log" => log
          }

          @pgbackups_client.should_receive(:create_transfer).and_return(@backup_obj)
          @pgbackups.stub!(:poll_transfer!).and_return(@backup_obj)
        end

        it 'aborts for a generic error' do
          stub_error_backup_with_log 'something generic'
          @pgbackups.should_receive(:error).with("An error occurred and your restore did not finish.")
          @pgbackups.restore
        end

        it 'aborts and informs for expired s3 urls' do
          stub_error_backup_with_log 'Invalid dump format: /tmp/aDMyoXPrAX/b031.dump: XML  document text'
          @pgbackups.should_receive(:error).with { |message| message.should =~ /backup url is invalid/ }
          @pgbackups.restore
        end
      end
    end
  end
end
