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
    context 'when file is a folder' do
      before { subject.mime_type = 'application/vnd.google-apps.folder' }
      it {
        expect(subject.icon).to eq(
          'https://drive-thirdparty.googleusercontent.com/128/type/' \
          'application/vnd.google-apps.folder'
        )
      }
    end

    context 'when file is a document' do
      before { subject.mime_type = 'application/vnd.google-apps.document' }
      it {
        expect(subject.icon).to eq(
          'https://drive-thirdparty.googleusercontent.com/128/type/' \
          'application/vnd.google-apps.document'
        )
      }
    end

    context 'when file is a spreadsheet' do
      before { subject.mime_type = 'application/vnd.google-apps.spreadsheet' }
      it {
        expect(subject.icon).to eq(
          'https://drive-thirdparty.googleusercontent.com/128/type/' \
          'application/vnd.google-apps.spreadsheet'
        )
      }
    end

    context 'when mime_type is nil' do
      before { subject.mime_type = nil }
      it { expect(subject.icon).to eq nil }
    end
  end
end
