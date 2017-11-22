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
