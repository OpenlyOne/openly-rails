# frozen_string_literal: true

RSpec.describe Contribution, type: :model do
  subject(:contribution) { build_stubbed :contribution }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project).dependent(false) }
    it do
      is_expected
        .to belong_to(:creator).class_name('Profiles::User').dependent(false)
    end
    it do
      is_expected
        .to belong_to(:branch).class_name('VCS::Branch').dependent(:destroy)
    end
  end

  describe 'delegations' do
    it do
      is_expected.to delegate_method(:branches).to(:project).with_prefix
      is_expected.to delegate_method(:revisions).to(:project).with_prefix
    end
  end

  describe 'validations' do
    it do
      is_expected.to validate_presence_of(:project).with_message('must exist')
    end
    it do
      is_expected.to validate_presence_of(:creator).with_message('must exist')
    end
    it do
      is_expected.to validate_presence_of(:branch).with_message('must exist')
    end
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:description) }

    context 'on setup' do
      it { is_expected.to validate_absence_of(:branch).on(:setup) }
      it { is_expected.to validate_presence_of(:title).on(:setup) }
      it { is_expected.to validate_presence_of(:description).on(:setup) }
    end
  end

  describe '#setup' do
    subject(:setup) { contribution.setup('attrs') }

    let(:is_valid) { true }

    before do
      allow(contribution).to receive(:assign_attributes)
      allow(contribution).to receive(:valid?).and_return is_valid
      allow(contribution).to receive(:create_fork_off_master_branch)
      allow(contribution).to receive(:save).and_return 'result-of-save'

      setup
    end

    it do
      expect(contribution).to have_received(:assign_attributes).with('attrs')
    end
    it { expect(contribution).to have_received(:valid?).with(:setup) }
    it { expect(contribution).to have_received(:create_fork_off_master_branch) }
    it { expect(contribution).to have_received(:save) }

    it 'returns the result of #save' do
      is_expected.to eq 'result-of-save'
    end

    context 'when it is not valid for setup' do
      let(:is_valid) { false }

      it { is_expected.to eq false }
      it { expect(contribution).not_to receive(:create_fork_off_master_branch) }
    end

    context 'when called without attributes' do
      subject(:setup) { contribution.setup }

      it { expect(contribution).to have_received(:assign_attributes).with({}) }
    end
  end

  describe '#create_fork_off_master_branch' do
    let(:new_project_branch)  { instance_double VCS::Branch }
    let(:root)                { instance_double VCS::FileInBranch }
    let(:creator)             { instance_double Profiles::User }
    let(:account)             { instance_double Account }
    let(:api_connection) do
      instance_double Providers::GoogleDrive::ApiConnection
    end

    before do
      allow(contribution).to receive(:branch=)
      allow(contribution)
        .to receive_message_chain(:project_branches, :create!)
        .and_return new_project_branch
      allow(contribution).to receive(:branch).and_return new_project_branch
      allow(new_project_branch).to receive(:create_remote_root_folder)
      allow(Providers::GoogleDrive::ApiConnection)
        .to receive(:default).and_return(api_connection)
      allow(api_connection).to receive(:share_file)
      allow(new_project_branch).to receive(:root).and_return root
      allow(root).to receive(:remote_file_id).and_return 'ext-root-id'
      allow(contribution).to receive(:creator).and_return creator
      allow(creator).to receive(:account).and_return account
      allow(account).to receive(:email).and_return 'em@il'
      allow(new_project_branch).to receive(:restore_commit)
      allow(contribution)
        .to receive_message_chain(:project_revisions, :last)
        .and_return 'last_commit'

      contribution.send(:create_fork_off_master_branch)
    end

    it 'sets branch to new project branch' do
      expect(contribution).to have_received(:branch=).with(new_project_branch)
    end

    it 'creates remote folder for new branch' do
      expect(new_project_branch).to have_received(:create_remote_root_folder)
    end

    it 'grants contribution creator write access to remote folder' do
      expect(api_connection)
        .to have_received(:share_file).with('ext-root-id', 'em@il', :writer)
    end

    it 'restores the last commit to the new branch' do
      expect(new_project_branch)
        .to have_received(:restore_commit)
        .with('last_commit', author: creator)
    end
  end
end
