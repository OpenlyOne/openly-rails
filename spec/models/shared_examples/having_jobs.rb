# frozen_string_literal: true

RSpec.shared_examples 'having jobs' do
  describe '#jobs' do
    subject { owning_object.jobs }
    let(:active_model_name) { instance_double ActiveModel::Name }

    before do
      allow(owning_object).to receive(:id).and_return 'id'
      allow(owning_object).to receive(:model_name).and_return active_model_name
      allow(active_model_name).to receive(:param_key).and_return 'type'
      allow(Delayed::Job)
        .to receive(:where)
        .with(delayed_reference_id: 'id', delayed_reference_type: 'type')
        .and_return 'referenced_jobs'
    end

    it 'returns all referenced jobs' do
      is_expected.to eq 'referenced_jobs'
    end
  end

  describe '#destroy_jobs' do
    let(:job_class) { class_double Delayed::Job }

    before { allow(owning_object).to receive(:jobs).and_return job_class }
    after  { owning_object.send :destroy_jobs }

    it 'calls #destroy_all on jobs' do
      expect(job_class).to receive(:destroy_all)
    end
  end
end
