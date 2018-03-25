# frozen_string_literal: true

RSpec.shared_examples 'being notifying' do
  it 'acts as notifiable' do
    expect(notifying).to respond_to :notify
    expect(notifying).to be_respond_to :notification_recipients, true
    expect(notifying).to be_respond_to :notification_source, true
    expect(notifying).to be_respond_to :trigger_notifications, true
  end
end
