# frozen_string_literal: true

RSpec.describe Henkei::Server, type: :model, vcr: true do
  subject(:server) { described_class }

  describe '#extract_text' do
    subject(:text) { server.extract_text(file) }

    let(:file_name) { 'file-with-link.docx' }
    let(:file)      { File.open(path_to_file_fixtures.join(file_name)) }
    let(:path_to_file_fixtures) do
      Rails.root.join('spec', 'support', 'fixtures', 'files')
    end

    it 'does not wrap links with new lines' do
      is_expected.not_to include "\ntrack@flov.com\n"
    end

    it 'trims newlines at document beginning and end' do
      is_expected.not_to match(/^\n.*\n$/)
    end

    context 'when file has no text' do
      let(:file_name) { 'image.png' }

      it 'returns empty string' do
        is_expected.not_to be nil
        is_expected.to be_empty
      end
    end
  end
end
