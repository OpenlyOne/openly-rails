# frozen_string_literal: true

RSpec.describe Providers::GoogleDrive::Link, type: :model do
  subject(:link) { Providers::GoogleDrive::Link }

  describe '.for(external_id:, mime_type:)' do
    before do
      allow(Providers::GoogleDrive::MimeType)
        .to receive(:to_symbol).with('type').and_return :symbolic_type
    end

    after { link.for(external_id: 'external-id', mime_type: 'type') }

    it 'calls #for_{symbolic_mime_type} with external_id' do
      expect(link).to receive(:send).with(:for_symbolic_type, 'external-id')
    end
  end

  describe '.for_document(id)' do
    subject { link.for_document('FILE-ID') }
    it { is_expected.to eq 'https://docs.google.com/document/d/FILE-ID' }
  end

  describe '.for_drawing(id)' do
    subject { link.for_drawing('FILE-ID') }
    it { is_expected.to eq 'https://docs.google.com/drawings/d/FILE-ID' }
  end

  describe '.for_folder(id)' do
    subject { link.for_folder('FILE-ID') }
    it { is_expected.to eq 'https://drive.google.com/drive/folders/FILE-ID' }
  end

  describe '.for_form(id)' do
    subject { link.for_form('FILE-ID') }
    it { is_expected.to eq 'https://docs.google.com/forms/d/FILE-ID' }
  end

  describe '.for_presentation(id)' do
    subject { link.for_presentation('FILE-ID') }
    it { is_expected.to eq 'https://docs.google.com/presentation/d/FILE-ID' }
  end

  describe '.for_spreadsheet(id)' do
    subject { link.for_spreadsheet('FILE-ID') }
    it { is_expected.to eq 'https://docs.google.com/spreadsheets/d/FILE-ID' }
  end

  describe '.for_other(id)' do
    subject { link.for_other('FILE-ID') }
    it { is_expected.to eq 'https://drive.google.com/file/d/FILE-ID' }
  end
end
