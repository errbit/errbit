describe Api::V1::CommentsController, type: 'controller' do
  context "when logged in" do
    before do
      @user = Fabricate(:user)
    end

    describe "GET /api/v1/problems/:problem_id/comments" do
      before do
        @problem = Fabricate(:problem)
        Fabricate(:comment, err: @problem)
        Fabricate(:comment, err: @problem)
        Fabricate(:comment)
      end

      it "should return JSON if JSON is requested" do
        get :index, params: { problem_id: @problem.id, auth_token: @user.authentication_token, format: "json" }
        expect { JSON.parse(response.body) }.not_to raise_error # JSON::ParserError
      end

      it "should return XML if XML is requested" do
        get :index, params: { problem_id: @problem.id, auth_token: @user.authentication_token, format: "xml" }
        expect(Nokogiri::XML(response.body).errors).to be_empty
      end

      it "should return JSON by default" do
        get :index, params: { problem_id: @problem.id, auth_token: @user.authentication_token }
        expect { JSON.parse(response.body) }.not_to raise_error # JSON::ParserError)
      end

      it "should return all comments of a problem" do
        get :index, params: { problem_id: @problem.id, auth_token: @user.authentication_token }
        expect(response).to be_successful
        comments = JSON.parse response.body
        expect(comments.length).to eq 2
      end
    end

    describe "POST /api/v1/problems/:problem_id/comments" do
      before do
        @problem = Fabricate(:problem)
      end

      context "with valid params" do
        it "should create comment" do
          expect do
            post :create, params: { problem_id: @problem.id, auth_token: @user.authentication_token, comment: { body: "I'll take a look at it." } }
          end.to change(Comment, :count)
          expect(response).to be_successful
        end
      end

      context "with invalid params" do
        it "shoudn't create comment" do
          expect do
            post :create, params: { problem_id: @problem.id, auth_token: @user.authentication_token, comment: { body: nil } }
          end.not_to change(Comment, :count)
          expect(response).not_to be_successful
          errors = JSON.parse response.body
          expect(errors).to eq("errors" => ["Body can't be blank"])
        end
      end
    end
  end
end
