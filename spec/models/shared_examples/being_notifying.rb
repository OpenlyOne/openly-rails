# frozen_string_literal: true

RSpec.shared_examples 'being notifying' do
  it 'acts as notifiable' do
    expect(notifying).to respond_to :notify
    expect(notifying).to be_respond_to :destroy_notifications, true
    expect(notifying).to be_respond_to :notification_recipients, true
    expect(notifying).to be_respond_to :notification_source, true
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

  describe '#trigger_notifications(key:)' do
    subject(:trigger) do
      notifying.send :trigger_notifications, 'model.action'
    end

    let(:notification_helper) { instance_double('Notifications::Model') }

    before do
      allow(notifying).to receive(:notification_helper=)
      allow(notifying).to receive(:notify)
      allow(Notification)
        .to receive(:notification_helper_for)
        .with(notifying, key: 'model.action')
        .and_return notification_helper
    end

    it 'sets the notification helper' do
      trigger
      expect(notifying)
        .to have_received(:notification_helper=)
        .with(notification_helper)
    end

    it 'notifies accounts' do
      trigger
      expect(notifying)
        .to have_received(:notify).with(:accounts, key: 'model.action')
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
