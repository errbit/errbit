describe AppDecorator do
  describe "#email_at_notices" do
    it 'return the list separate by comma' do
      expect(AppDecorator.new(double(email_at_notices: [2, 3])).email_at_notices).to eql '2, 3'
    end
  end

  describe "#notify_user_display" do
    it 'return display:none if notify' do
      expect(AppDecorator.new(double(notify_all_users: true)).notify_user_display).to eql 'display: none;'
    end

    it 'return blank if no notify' do
      expect(AppDecorator.new(double(notify_all_users: false)).notify_user_display).to eql ''
    end
  end

  describe "#notify_err_display" do
    it 'return display:none if no notify' do
      expect(AppDecorator.new(double(notify_on_errs: false)).notify_err_display).to eql 'display: none;'
    end

    it 'return blank if no notify' do
      expect(AppDecorator.new(double(notify_on_errs: true)).notify_err_display).to eql ''
    end
  end
end
