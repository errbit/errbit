shared_examples_for "Net::HTTP" do
  describe "when making real requests", :net_connect => true do
    let(:port){ WebMockServer.instance.port }

    before(:each) do
      @http = Net::HTTP.new("localhost", port)
    end

    it "should return a Net::ReadAdapter from response.body when a real request is made with a block and #read_body", :net_connect => true do
      response = Net::HTTP.new("localhost", port).request_get('/') { |r| r.read_body { } }
      response.body.should be_a(Net::ReadAdapter)
    end

    it "should handle requests with block passed to read_body", :net_connect => true do
      body = ""
      req = Net::HTTP::Get.new("/")
      Net::HTTP.start("localhost", port) do |http|
        http.request(req) do |res|
          res.read_body do |str|
            body << str
          end
        end
      end
      body.should =~ /hello world/
    end

    it "should connect only once when connected on start", :net_connect => true do
      @http = Net::HTTP.new('localhost', port)
      socket_id_before_request = socket_id_after_request = nil
      @http.start {|conn|
        socket_id_before_request = conn.instance_variable_get(:@socket).object_id
        conn.request(Net::HTTP::Get.new("/"))
        socket_id_after_request = conn.instance_variable_get(:@socket).object_id
      }
      socket_id_after_request.should_not be_nil
      socket_id_after_request.should == socket_id_before_request
    end

    describe "without start" do
      it "should close connection after a real request" do
        @http.get('/') { }
        @http.should_not be_started
      end

      it "should execute block exactly once" do
        times = 0
        @http.get('/') { times += 1 }
        times.should == 1
      end

      it "should have socket open during a real request" do
        socket_id = nil
        @http.get('/') {
          socket_id = @http.instance_variable_get(:@socket).object_id
        }
        socket_id.should_not be_nil
      end

      it "should be started during a real request" do
        started = nil
        @http.get('/') {
          started = @http.started?
        }
        started.should == true
        @http.started?.should == false
      end
    end

    describe "with start" do
      it "should close connection after a real request" do
        @http.start {|conn| conn.get('/') { } }
        @http.should_not be_started
      end

      it "should execute block exactly once" do
        times = 0
        @http.start {|conn| conn.get('/') { times += 1 }}
        times.should == 1
      end

      it "should have socket open during a real request" do
        socket_id = nil
        @http.start {|conn| conn.get('/') {
            socket_id = conn.instance_variable_get(:@socket).object_id
          }
        }
        socket_id.should_not be_nil
      end

      it "should be started during a real request" do
        started = nil
        @http.start {|conn| conn.get('/') {
            started = conn.started?
          }
        }
        started.should == true
        @http.started?.should == false
      end
    end

    describe "with start without request block" do
      it "should close connection after a real request" do
        @http.start {|conn| conn.get('/') }
        @http.should_not be_started
      end

      it "should have socket open during a real request" do
        socket_id = nil
        @http.start {|conn|
          socket_id = conn.instance_variable_get(:@socket).object_id
        }
        socket_id.should_not be_nil
      end

      it "should be started during a real request" do
        started = nil
        @http.start {|conn|
          started = conn.started?
        }
        started.should == true
        @http.started?.should == false
      end
    end
  end
end