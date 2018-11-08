# frozen_string_literal: true

RSpec.describe ContentDownloadJob, type: :job do
  subject(:job) { ContentDownloadJob.new }

  it { expect(subject.priority).to eq 50 }
  it { expect(subject.queue_name).to eq 'content_download' }

  describe '#perform' do
    subject(:run_job)   { job.perform(x: 'y') }
    let(:content)       { instance_double VCS::Content }
    let(:downloader)    { instance_double VCS::Operations::ContentDownloader }

    before do
      allow(job).to receive(:variables_from_arguments).with(x: 'y')
      allow(job).to receive(:content).and_return content
      allow(content).to receive(:update!)
      allow(job).to receive(:downloader).and_return downloader
      allow(downloader).to receive(:plain_text).and_return 'text'
      allow(downloader).to receive(:done)
      run_job
    end

    it 'updates content with plain text' do
      expect(content).to have_received(:update!).with(plain_text: 'text')
    end

    it 'closes downloader' do
      expect(downloader).to have_received(:done)
    end
  end
end
