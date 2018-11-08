# frozen_string_literal: true

RSpec.shared_examples 'vcs: being downloadable' do
  describe 'callbacks' do
    describe 'after save' do
      subject { downloadable }

      before do
        allow(downloadable).to receive(:download_content)
        allow(downloadable)
          .to receive(:download_on_save?).and_return backup_on_save
        downloadable.save
      end

      context 'when download_on_save? is true' do
        let(:download_on_save) { true }

        it { is_expected.to have_received(:download_content) }
      end

      context 'when download_on_save? is false' do
        let(:download_on_save) { false }

        it { is_expected.not_to have_received(:download_content) }
      end
    end
  end

  describe 'delegations' do
    it do
      is_expected.to delegate_method(:content).to(:current_snapshot).allow_nil
    end
    it { is_expected.to delegate_method(:text_type?).to(:mime_type_instance) }
    it { is_expected.to delegate_method(:downloaded?).to(:content).with_prefix }
  end

  describe '#download_on_save?' do
    subject { backupable }

    let(:is_text_type)  { true }
    let(:is_backed_up)  { true }
    let(:is_downloaded) { false }

    before do
      allow(backupable).to receive(:text_type?).and_return is_text_type
      allow(backupable).to receive(:backed_up?).and_return is_backed_up
      allow(backupable)
        .to receive(:content_downloaded?).and_return is_downloaded
    end

    it { is_expected.to be_download_on_save }

    context 'when not text' do
      let(:is_text_type) { false }

      it { is_expected.not_to be_download_on_save }
    end

    context 'when not backed up' do
      let(:is_backed_up) { false }

      it { is_expected.not_to be_download_on_save }
    end

    context 'when downloaded' do
      let(:is_downloaded) { true }

      it { is_expected.not_to be_download_on_save }
    end
  end

  describe '#download_content' do
    subject(:download_content) { backupable.download_content }

    before do
      allow(VCS::Operations::Downloader).to receive(:new).and_return downloader
      allow(downloader).to receive(:plain_text).and_return 'plain_text'
      allow(downloadable).to receive(:content).and_return content
      allow(content).to receive(:update!)
      allow(downloader).to receive(:done)
      download_content
    end

    it 'updates content with plain text' do
      expect(content).to have_received(:update!).with(plain_text: 'plain_text')
    end

    it 'closes downloader' do
      expect(downloader).to have_received(:done)
    end
  end
end
