# frozen_string_literal: true

RSpec.describe NotificationsMailer, type: :mailer do
  describe '.send_notification_email(notification, options = {})' do
    after { described_class.send_notification_email('notification', x: 'y') }

    it 'calls .notification_email with reference' do
      expect(described_class)
        .to receive(:notification_email)
        .with('notification', x: 'y', reference: 'notification')
    end
  end

  describe '#notification_email' do
    let(:notification) { build_stubbed :notification }
    let(:mail) { described_class.notification_email(notification).deliver_now }

    it 'sets the correct subject' do
      expect(mail.subject).to eq notification.subject_line
    end

    it 'sets the correct recipient' do
      expect(mail.to).to contain_exactly notification.target.email
      expect(mail[:to].display_names)
        .to contain_exactly notification.target.user.name
    end

    it 'sets the correct sender' do
      expect(mail.from).to contain_exactly 'notification@upshift.one'
      expect(mail[:from].display_names).to contain_exactly 'Upshift One'
    end

    it 'includes notification url' do
      expect(mail.body.encoded).to match(notifications_url(notification))
    end
  end
end
