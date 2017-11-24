# frozen_string_literal: true

RSpec.shared_examples 'being a file item' do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it {
      is_expected.to belong_to(:parent).class_name('FileItems::Folder')
      # .optional <- TODO: Upgrade shoulda-matchers gem and enable optional
    }
  end

  describe '#external_link' do
    it { expect(subject).to respond_to :external_link }
  end

  describe '#icon' do
    it { expect(subject).to respond_to :icon }
  end

  describe '#modified_since_last_commit?' do
    before { subject.modified_time_at_last_commit = time }
    let!(:time) { Time.zone.now.utc }

    context 'when modified_time > modified_time_at_last_commit' do
      before  { subject.modified_time = time.tomorrow }
      it      { expect(subject).to be_modified_since_last_commit }
    end
    context 'when modified_time = modified_time_at_last_commit' do
      before  { subject.modified_time = time }
      it      { expect(subject).not_to be_modified_since_last_commit }
    end
    context 'when modified_time < modified_time_at_last_commit' do
      before  { subject.modified_time = time.yesterday }
      it      { expect(subject).not_to be_modified_since_last_commit }
    end
    context 'when modified time is nil' do
      before  { subject.modified_time = nil }
      it      { is_expected.not_to be_modified_since_last_commit }
    end
    context 'when modified time at last commit is nil' do
      before  { subject.modified_time_at_last_commit = nil }
      it      { is_expected.not_to be_modified_since_last_commit }
    end
    context 'when modified time and modified time at last commit are nil' do
      before  { subject.modified_time = nil }
      before  { subject.modified_time_at_last_commit = nil }
      it      { is_expected.not_to be_modified_since_last_commit }
    end
  end
end
