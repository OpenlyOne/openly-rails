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

  describe 'EXPORT_FORMATS' do
    subject { type::EXPORT_FORMATS }
    it { is_expected.to have_key(:document) }
    it { is_expected.to have_key(:spreadsheet) }
    it { is_expected.to have_key(:drawing) }
    it { is_expected.to have_key(:presentation) }
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

  describe '#exportable?' do
    subject(:type) { described_class.new(mime_type) }

    context 'when mime_type is document' do
      let(:mime_type) { described_class.document }

      it { is_expected.to be_exportable }
    end

    context 'when mime_type is PDF' do
      let(:mime_type) { described_class.pdf }

      it { is_expected.not_to be_exportable }
    end
  end

  describe '#export_as' do
    subject(:export_as) { type.export_as }

    let(:type) { described_class.new(described_class.document) }

    it { is_expected.to eq described_class::EXPORT_FORMATS[:document] }
  end

  describe '#text_type?' do
    subject { described_class.new(mime_type) }

    context 'when mime type is document' do
      let(:mime_type) { type.document }

      it { is_expected.to be_text_type }
    end

    context 'when mime type is PDF' do
      let(:mime_type) { type.pdf }

      it { is_expected.to be_text_type }
    end

    context 'when mime type is other' do
      let(:mime_type) { 'word-document' }

      it { is_expected.not_to be_text_type }
    end
  end
end
