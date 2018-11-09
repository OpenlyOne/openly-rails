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

    let(:backup)  { instance_double VCS::FileBackup }
    let(:content) { instance_double VCS::Content }

    before do
      allow(ContentDownloadJob).to receive(:perform_later)
      allow(ContentDownloadJob).to receive(:perform_now)
      allow(backupable).to receive(:backup).and_return backup
      allow(backupable).to receive(:content).and_return content
      allow(backup).to receive(:external_id).and_return 'ext-id'
      allow(content).to receive(:id).and_return 'content-id'
    end

    it 'creates ContentDownloadJob' do
      expect(ContentDownloadJob)
        .to have_received(:perform_later)
        .with(remote_file_id: 'ext-id', content_id: 'content-id')
    end

    context 'when force_sync is true' do
      before { allow(backupable).to receive(:force_sync).and_return true }

      it 'executes ContentDownloadJob immediately' do
        expect(ContentDownloadJob)
          .to have_received(:perform_now)
          .with(remote_file_id: 'ext-id', content_id: 'content-id')
      end
    end
  end
end
