# frozen_string_literal: true

RSpec.shared_examples 'being a file item' do
  before { allow(NotificationChannelJob).to receive(:perform_later) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it {
      is_expected.to belong_to(:parent).class_name('FileItems::Folder')
      # .optional <- TODO: Upgrade shoulda-matchers gem and enable optional
    }
    it {
      is_expected.to have_many(:notification_channels)
        .with_foreign_key('file_item_id').dependent(:destroy)
    }
  end

  describe 'callbacks' do
    context 'after create' do
      it 'creates a NotificationChannelJob' do
        expect(NotificationChannelJob).to receive(:perform_later)
          .with(
            reference_type:   'project',
            reference_id:     subject.project_id,
            file_id:          kind_of(Numeric),
            google_drive_id:  subject.google_drive_id
          )
        subject.save
      end
    end
  end

  describe '#external_link' do
    it { expect(subject).to respond_to :external_link }
  end

  describe '#icon' do
    it { expect(subject).to respond_to :icon }
  end

  describe '#modified?' do
    before { subject.version_at_last_commit = 9 }

    context 'when version is 10' do
      before  { subject.version = 10 }
      it      { expect(subject).to be_modified }
    end
    context 'when version is 9' do
      before  { subject.version = 9 }
      it      { expect(subject).not_to be_modified }
    end
    context 'when version is 8' do
      before  { subject.version = 8 }
      it      { expect(subject).not_to be_modified }
    end
  end
end
