# frozen_string_literal: true

RSpec.describe VCS::Operations::ContentGenerator, type: :model do
  subject(:generator) { described_class.new(attributes) }
  let(:attributes) do
    {
      repository: repository,
      remote_file_id: remote_file_id,
      remote_content_version_id: remote_content_version_id
    }
  end
  let(:repository) { instance_double VCS::Repository }
  let(:remote_file_id) { 'remote-id' }
  let(:remote_content_version_id) { 'content-vers' }

  describe '.generate(attributes)' do
    subject(:generate)  { described_class.generate(attributes) }
    let(:attributes)    { 'attrs' }
    let(:instance)      { instance_double described_class }

    before do
      allow(described_class).to receive(:new).and_return instance
      allow(instance).to receive(:generate).and_return 'generated'
    end

    it 'initializes a new instance and calls #generate' do
      generate
      expect(described_class).to have_received(:new).with(attributes)
      expect(instance).to have_received(:generate)
      is_expected.to eq 'generated'
    end
  end

  describe '#initialize(attributes)' do
    subject(:init) { described_class.new(attributes) }

    it { is_expected.to be_a described_class }

    context 'when attributes is missing repository' do
      before { attributes.except!(:repository) }

      it { expect { init }.to raise_error(KeyError) }
    end

    context 'when attributes is missing remote_file_id' do
      before { attributes.except!(:remote_file_id) }

      it { expect { init }.to raise_error(KeyError) }
    end

    context 'when attributes is missing remote_content_version_id' do
      before { attributes.except!(:remote_content_version_id) }

      it { expect { init }.to raise_error(KeyError) }
    end
  end

  describe '#generate' do
    subject(:generate) { generator.generate }

    before do
      remote_content = instance_double VCS::RemoteContent
      allow(generator).to receive(:remote_content).and_return remote_content
      allow(remote_content).to receive(:content).and_return 'content'
    end

    it 'returns content of remote_content' do
      is_expected.to eq 'content'
    end
  end
end
