# frozen_string_literal: true

RSpec.describe Notifications::Replies::Create, type: :model do
  subject(:notification)  { described_class.new(reply) }
  let(:reply)             { instance_double Reply }

  describe '#path' do
    subject(:path)      { notification.path }
    let(:project)       { instance_double Project }
    let(:contribution)  { instance_double Contribution }

    before do
      allow(notification).to receive(:project).and_return project
      allow(notification).to receive(:contribution).and_return contribution
      allow(project).to receive(:owner).and_return 'owner'
      allow(reply).to receive(:id).and_return '44'
      allow(notification)
        .to receive(:profile_project_contribution_replies_path)
        .with('owner', project, contribution, anchor: 'reply-44')
        .and_return 'path'
    end

    it { is_expected.to eq 'path' }
  end

  describe '#source' do
    subject(:source) { notification.source }
    before { allow(reply).to receive(:author).and_return 'author' }

    it { is_expected.to eq 'author' }
  end

  describe '#title' do
    subject             { notification.title }
    let(:source)        { instance_double Profiles::User }
    let(:contribution)  { instance_double Contribution }

    before do
      allow(notification).to receive(:source).and_return source
      allow(notification).to receive(:contribution).and_return contribution
      allow(source).to receive(:name).and_return 'User'
      allow(contribution).to receive(:title).and_return 'CTITLE'
    end

    it { is_expected.to eq 'User replied to CTITLE' }
  end
end
