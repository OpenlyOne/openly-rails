# frozen_string_literal: true

RSpec.describe Notifications::Contributions::Create, type: :model do
  subject(:notification)  { described_class.new(contribution) }
  let(:contribution)      { instance_double Contribution }

  describe '#path' do
    subject(:path)  { notification.path }
    let(:project)   { instance_double Project }

    before do
      allow(notification).to receive(:project).and_return project
      allow(project).to receive(:owner).and_return 'owner'
      allow(notification)
        .to receive(:profile_project_contribution_path)
        .with('owner', project, contribution)
        .and_return 'path'
    end

    it { is_expected.to eq 'path' }
  end

  describe '#source' do
    subject(:source) { notification.source }
    before { allow(contribution).to receive(:creator).and_return 'creator' }

    it { is_expected.to eq 'creator' }
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

    it { is_expected.to eq 'User created a contribution in Project' }
  end
end
