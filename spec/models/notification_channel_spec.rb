# frozen_string_literal: true

RSpec.describe Project, type: :model do
  subject(:notification_channel) { build_stubbed(:notification_channel) }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:file).class_name('FileItems::Base') }
  end

  describe 'attributes' do
    it { should define_enum_for(:status).with(%w[pending active]) }
  end

  describe '#channel_name' do
    subject(:method) { notification_channel.unique_channel_name }

    context 'when id is 1' do
      before  { notification_channel.id = 1 }
      it      { is_expected.to start_with 'channel-test-1-' }
    end

    context 'when id is 7523' do
      before  { notification_channel.id = 7523 }
      it      { is_expected.to start_with 'channel-test-7523-' }
    end

    context 'when id is nil' do
      before  { notification_channel.id = nil }
      it      { is_expected.to be nil }
    end
  end
end
