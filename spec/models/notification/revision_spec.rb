# frozen_string_literal: true

RSpec.describe Notification::Revision, type: :model do
  subject(:notification)  { described_class.new(revision) }
  let(:revision)          { instance_double Revision }

  describe '#path' do
    subject(:path)  { notification.path }
    let(:project)   { instance_double Project }

    before do
      allow(revision).to receive(:project).and_return project
      allow(project).to receive(:owner).and_return 'owner'
      allow(notification)
        .to receive(:profile_project_revisions_path)
        .with('owner', project)
        .and_return 'path'
    end

    it { is_expected.to eq 'path' }
  end

  describe '#source' do
    subject(:source) { notification.source }
    before { allow(revision).to receive(:author).and_return 'author' }

    it { is_expected.to eq 'author' }
  end
end
