# frozen_string_literal: true

RSpec.describe NotificationsMailer, type: :mailer do
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
