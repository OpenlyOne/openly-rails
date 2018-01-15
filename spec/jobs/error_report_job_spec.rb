# frozen_string_literal: true

RSpec.describe ErrorReportJob, type: :job do
  subject(:job) { ErrorReportJob.perform_later(payload) }
  let(:payload) { { pay: 'load' } }

  describe 'priority', delayed_job: true do
    it { expect(subject.priority).to eq 1 }
  end

  describe 'queue', delayed_job: true do
    it { expect(subject.queue_name).to eq 'error_report' }
  end

  describe '.call(payload)' do
    it 'creates an ErrorReportJob' do
      expect(ErrorReportJob).to receive(:perform_later).with kind_of(Hash)
      ErrorReportJob.call(payload)
    end
  end

  describe '#perform' do
    it 'sends the error to Rollbar' do
      expect(Rollbar).to receive(:process_from_async_handler).with(payload)
      subject
    end
  end
end
