# frozen_string_literal: true

RSpec.describe VCS::Operations::ContentDownloader, type: :model do
  subject(:downloader) { described_class.new(remote_file_id: 'remote_file_id') }

  describe '#plain_text' do
    subject(:plain_text) { downloader.plain_text }

    let(:text)  { 'text from parser' }
    let(:file)  { instance_double File }

    before do
      allow(Henkei::Server).to receive(:extract_text).with(file).and_return text
      allow(downloader).to receive(:downloaded_file).and_return file
    end

    it { is_expected.to eq 'text from parser' }

    context 'when text contains leading and trailing whitespace' do
      let(:text) { "\n\n SOME TEXT \n \n     \n" }

      it 'strips whitespace' do
        is_expected.to eq 'SOME TEXT'
      end
    end

    context 'when plain_text is cached' do
      before { downloader.instance_variable_set :@plain_text, 'CACHED' }

      it { is_expected.to eq 'CACHED' }
    end
  end
end
