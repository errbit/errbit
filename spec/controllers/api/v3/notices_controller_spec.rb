describe Api::V3::NoticesController, type: :controller do
  let(:app) { Fabricate(:app) }

  it 'responds to OPTIONS request and sets CORS headers' do
    process :create, 'OPTIONS', project_id: app.api_key
    expect(response).to be_success
    expect(response.headers['Access-Control-Allow-Origin']).to eq('*')
    expect(response.headers['Access-Control-Allow-Headers']).to eq('origin, content-type, accept')
  end

  it 'sets CORS headers on POST request' do
    post :create, project_id: 'invalid id'
    expect(response.headers['Access-Control-Allow-Origin']).to eq('*')
    expect(response.headers['Access-Control-Allow-Headers']).to eq('origin, content-type, accept')
  end

  it 'returns created notice id in json format' do
    json = Rails.root.join('spec', 'fixtures', 'api_v3_request.json').read
    data = JSON.parse(json)
    data['project_id'] = app.api_key
    data['key'] = app.api_key
    post :create, data
    notice = Notice.last
    expect(response.body).to eq({ notice: { id: notice.id } }.to_json)
  end

  it 'responds with 400 when request attributes are not valid' do
    allow_any_instance_of(AirbrakeApi::V3::NoticeParser).to receive(:report).and_raise(AirbrakeApi::ParamsError)
    post :create, project_id: 'ID'
    expect(response.status).to eq(400)
    expect(response.body).to eq('Invalid request')
  end

  it 'responds with 422 when api_key or project_id is invalid' do
    json = Rails.root.join('spec', 'fixtures', 'api_v3_request.json').read
    data = JSON.parse(json)
    data['project_id'] = 'invalid'
    data.delete('key')
    post :create, data
    expect(response.status).to eq(422)
    expect(response.body).to eq('Your API key is unknown')
  end

  it 'ignores notices for older api' do
    upgraded_app = Fabricate(:app, current_app_version: '2.0')
    json = Rails.root.join('spec', 'fixtures', 'api_v3_request.json').read
    data = JSON.parse(json)
    data['project_id'] = upgraded_app.api_key
    data['key'] = upgraded_app.api_key
    post :create, data
    expect(response.body).to eq('Notice for old app version ignored')
    expect(Notice.count).to eq(0)
  end
end