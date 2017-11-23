# frozen_string_literal: true

RSpec.describe NotificationChannelJob, type: :job do
  subject(:job) { NotificationChannelJob.perform_later({}) }

  describe 'priority', delayed_job: true do
    it { expect(subject.priority).to eq 60 }
  end

  describe 'queue', delayed_job: true do
    it { expect(subject.queue_name).to eq 'notification_channel' }
  end

  describe '#perform' do
    before do
      mock_google_drive_requests if ENV['MOCK_GOOGLE_DRIVE_REQUESTS'] == 'true'
    end
    subject(:method) do
      NotificationChannelJob.perform_later(
        reference: project,
        file_id: file.id,
        google_drive_id: file.google_drive_id
      )
    end
    let(:project) { create :project }
    let!(:file) do
      create :file_items_base,
             google_drive_id: Settings.google_drive_test_folder_id,
             project: project
    end
    let(:channel) { NotificationChannel.last }

    it 'creates a NotificationChannel' do
      expect { subject }.to change(NotificationChannel, :count).by(1)
      expect(channel.project).to eq project
      expect(channel.file.id).to eq file.id
    end

    it 'starts watching the file' do
      expect(GoogleDrive).to receive(:watch_file)
        .with(kind_of(String), file.google_drive_id)
        .and_return(GoogleDriveHelper.watch_file('any', 'file'))
      subject
    end

    it 'updates NotificationChannel with expirates_at' do
      subject
      expect(channel.expires_at)
        .to be_within(13.hours).of(Time.zone.now + 12.hours)
    end
  end
end
