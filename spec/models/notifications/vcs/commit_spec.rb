# frozen_string_literal: true

RSpec.describe Notifications::VCS::Commit, type: :model do
  subject(:notification)  { described_class.new(revision) }
  let(:revision)          { instance_double VCS::Commit }

  describe '#path' do
    subject(:path)  { notification.path }
    let(:project)   { instance_double Project }

    before do
      allow(notification).to receive(:project).and_return project
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

  describe '#title' do
    subject       { notification.title }
    let(:source)  { instance_double Profiles::User }
    let(:project) { instance_double Project }

    before do
      allow(notification).to receive(:source).and_return source
      allow(notification).to receive(:project).and_return project
      allow(source).to receive(:name).and_return 'User'
      allow(project).to receive(:title).and_return 'Project'
    end

    it { is_expected.to eq 'User created a revision in Project' }
  end
end
