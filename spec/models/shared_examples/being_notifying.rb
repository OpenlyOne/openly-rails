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
end
