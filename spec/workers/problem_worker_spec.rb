describe ProblemWorker, type: 'model' do
  let(:app) { Fabricate(:app, :email_at_notices => [1], :notification_service => Fabricate(:campfire_notification_service))}
  let(:err) { Fabricate(:err, :problem => Fabricate(:problem, :app => app, :notices_count => 100)) }
  let(:backtrace) { Fabricate(:backtrace) }

  it 'should call create notification on problem notification service' do
    # Because the worker is looking for problem again by find method
    # it's required to stub notification service method
    campy = double('CampfireService')
    allow(Campy::Room).to receive(:new).and_return(campy)
    allow(campy).to receive(:speak).and_return(true)

    # assert
    expect(campy).to receive(:speak)

    # Send a problem
    ProblemWorker.new.perform(err.problem.id)
  end
end
