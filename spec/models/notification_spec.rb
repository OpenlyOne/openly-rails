# frozen_string_literal: true

RSpec.describe Notification, type: :model do
  subject(:notification) { build_stubbed :notification }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  describe 'hash ids' do
    it '#to_param returns a hash id' do
      expect(notification.to_param).to be_an_instance_of String
    end
  end
end
