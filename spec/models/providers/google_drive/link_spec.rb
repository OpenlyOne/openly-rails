# frozen_string_literal: true

RSpec.describe Providers::GoogleDrive::Link, type: :model do
  subject(:link) { Providers::GoogleDrive::Link }

  describe '.for(remote_file_id:, mime_type:)' do
    before do
      allow(Providers::GoogleDrive::MimeType)
        .to receive(:to_symbol).with('type').and_return :symbolic_type
    end

    after { link.for(remote_file_id: 'external-id', mime_type: 'type') }

    it 'calls #for_{symbolic_mime_type} with remote_file_id' do
      expect(link)
        .to receive(:safe_send).with(:for_symbolic_type, 'external-id')
    end

    context 'when safe_send returns nil' do
      before do
        allow(Providers::GoogleDrive::Link)
          .to receive(:safe_send)
          .with(:for_symbolic_type, 'external-id')
          .and_return nil
      end

      it { expect(link).to receive(:for_other).with('external-id') }
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

  describe '.safe_send(method, arguments)' do
    before do
      allow(link).to receive(:respond_to?).and_call_original
      allow(link)
        .to receive(:respond_to?).with(:method_name).and_return method_exists
    end

    after { link.safe_send(:method_name, a: 1, b: 2) }

    context 'when method exists' do
      let(:method_exists) { true }

      it { is_expected.to receive(:send).with(:method_name, a: 1, b: 2) }
    end

    context 'when method does not exist' do
      let(:method_exists) { false }

      it { is_expected.not_to receive(:send).with(:method_name, a: 1, b: 2) }
      it { expect(link.safe_send(:method_name, a: 1, b: 2)).to eq nil }
    end
  end
end
