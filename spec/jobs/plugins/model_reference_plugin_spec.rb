# frozen_string_literal: true

# Dummy class for this spec
class TestJob < ApplicationJob
  queue_as :default

  def perform(*args); end
end

RSpec.describe ModelReferencePlugin, delayed_job: true do
  subject(:job)   { Delayed::Job.first }
  let(:reference) { create :user }
  before          { TestJob.perform_later(arguments) }

  context 'when a model reference is passed as an argument to the job' do
    let(:arguments) { { reference: reference, other_arg: 'test!' } }

    it "saves the reference's ID to the database" do
      expect(job.delayed_reference_id).to eq reference.id
    end

    it "saves the reference's type to the database" do
      expect(job.delayed_reference_type).to eq reference.model_name.param_key
    end
  end

  context 'when a model reference is not passed as an argument to the job' do
    let(:arguments) { { first_arg: 'no reference!', another_arg: 'indeed' } }

    it 'saves neither reference ID nor type to the database' do
      expect(job.delayed_reference_id).to eq nil
      expect(job.delayed_reference_type).to eq nil
    end
  end
end
