# frozen_string_literal: true

RSpec.describe Providers::GoogleDrive::MimeType, type: :model do
  subject(:type) { Providers::GoogleDrive::MimeType }

  describe 'MIME_TYPES' do
    subject { type::MIME_TYPES }
    it { is_expected.to have_key(:document) }
    it { is_expected.to have_key(:drawing) }
    it { is_expected.to have_key(:folder) }
    it { is_expected.to have_key(:form) }
    it { is_expected.to have_key(:presentation) }
    it { is_expected.to have_key(:spreadsheet) }
  end

  describe 'getter methods' do
    it { expect(type.document).to eq 'application/vnd.google-apps.document' }
    it { expect(type.folder).to   eq 'application/vnd.google-apps.folder' }
    it do
      expect(type.spreadsheet).to eq 'application/vnd.google-apps.spreadsheet'
    end
  end

  describe 'checker methods' do
    it { expect(type).to be_document('application/vnd.google-apps.document') }
    it { expect(type).to be_folder('application/vnd.google-apps.folder') }
    it do
      expect(type).to be_spreadsheet('application/vnd.google-apps.spreadsheet')
    end
  end

  describe '.to_symbol(mime_type)' do
    subject         { type.to_symbol(mime_type) }
    let(:mime_type) { type.document }
    it              { is_expected.to eq :document }

    context 'when mime type is not defined' do
      let(:mime_type) { 'other-mime-type' }
      it              { is_expected.to eq :other }
    end
  end
end
