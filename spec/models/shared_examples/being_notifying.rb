# frozen_string_literal: true

RSpec.shared_examples 'being notifying' do
  it 'acts as notifiable' do
    expect(notifying).to respond_to :notify
    expect(notifying).to be_respond_to :destroy_notifications, true
    expect(notifying).to be_respond_to :notification_recipients, true
    expect(notifying).to be_respond_to :notification_source, true
    expect(notifying).to be_respond_to :path_to_notifying_object, true
    expect(notifying).to be_respond_to :trigger_notifications, true
  end

  it 'has a helper class' do
    expect { notifying.send(:notification_helper) }.not_to raise_error
  end

  it 'has skip_notifications attribute' do
    expect(notifying).to respond_to :skip_notifications=
    expect(notifying).to respond_to :skip_notifications
  end

  describe '#skip_notifications?' do
    it { is_expected.not_to be_skip_notifications }

    context 'when skip_notifications = true' do
      before { notifying.skip_notifications = true }

      it { is_expected.to be_skip_notifications }
    end
  end

  describe '#trigger_notifications(key: nil)' do
    subject(:trigger) { notifying.send :trigger_notifications, key: 'key' }

    before { allow(notifying).to receive(:notify) }

    it do
      trigger
      expect(notifying).to have_received(:notify).with(:accounts, key: 'key')
    end

    context 'when skip_notifications? is true' do
      before do
        allow(notifying).to receive(:skip_notifications?).and_return true
      end

      it do
        trigger
        expect(notifying).not_to have_received(:notify)
      end
    end
  end
end
