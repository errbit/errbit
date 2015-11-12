describe Api::V3::NoticesController, type: :controller do
  let(:app) { Fabricate(:app) }
  let(:project_id) { app.api_key }
  let(:legit_params) { { project_id: project_id, key: project_id } }
  let(:legit_body) do
    Rails.root.join('spec', 'fixtures', 'api_v3_request.json').read
  end

  it 'sets CORS headers on POST request' do
    post :create, project_id: 'invalid id'
    expect(response.headers['Access-Control-Allow-Origin']).to eq('*')
    expect(response.headers['Access-Control-Allow-Headers']).to eq('origin, content-type, accept')
  end

  it 'returns created notice id in json format' do
    post :create, legit_body, legit_params
    notice = Notice.last
    expect(JSON.parse(response.body)).to eq(
      'id'  => notice.id.to_s,
      'url' => app_problem_url(app, notice.problem)
    )
  end

  it 'responds with 400 when request attributes are not valid' do
    allow_any_instance_of(AirbrakeApi::V3::NoticeParser).
      to receive(:report).and_raise(AirbrakeApi::ParamsError)
    post :create, project_id: 'ID'
    expect(response.status).to eq(400)
    expect(response.body).to eq('Invalid request')
  end

  it 'responds with 422 when project_id is invalid' do
    post :create, legit_body, project_id: 'hm?', key: 'wha?'

    expect(response.status).to eq(422)
    expect(response.body).to eq('Your API key is unknown')
  end

  it 'ignores notices for older api' do
    app = Fabricate(:app, current_app_version: '2.0')
    post :create, legit_body, project_id: app.api_key, key: app.api_key
    expect(response.body).to eq('Notice for old app version ignored')
    expect(Notice.count).to eq(0)
  end
end
