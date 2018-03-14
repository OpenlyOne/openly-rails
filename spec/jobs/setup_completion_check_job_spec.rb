# frozen_string_literal: true

RSpec.describe SetupCompletionCheckJob, type: :job do
  subject(:job) { SetupCompletionCheckJob.new }

  it { expect(subject.priority).to eq 100 }
  it { expect(subject.queue_name).to eq 'setup_completion_check' }

  describe '#perform' do
    subject(:method)    { job.perform(x: 'y') }
    let(:setup)         { instance_double Project::Setup }
    let(:is_completed)  { false }

    before do
      allow(job).to receive(:variables_from_arguments).with(x: 'y')
      allow(job).to receive(:setup).and_return setup
      allow(setup).to receive(:check_if_complete)
      allow(setup).to receive(:completed?).and_return is_completed
      allow(setup).to receive(:schedule_setup_completion_check_job)
    end

    after { method }

    it { expect(setup).to receive(:check_if_complete) }

    it { expect(setup).to receive(:schedule_setup_completion_check_job) }

    context 'when setup is completed' do
      let(:is_completed) { true }
      it { expect(setup).not_to receive(:schedule_setup_completion_check_job) }
    end
  end
end
