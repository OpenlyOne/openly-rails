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
  let(:repository) { create :vcs_repository }
  let(:remote_file_id) { 'remote-id' }
  let(:remote_content_version_id) { 'content-vers' }

  describe '#generate(attributes)' do
    subject(:content) { generator.generate }

    it 'returns a new, persisted instance of VCS::Content' do
      expect(content).to be_a VCS::Content
      expect(content).to have_attributes(repository: repository)
    end

    context 'when content for those attributes already exists' do
      let!(:existing_content) { described_class.new(attributes).generate }

      it 'returns the existing VCS::Content' do
        expect(content).to eq existing_content
      end
    end
  end
end
