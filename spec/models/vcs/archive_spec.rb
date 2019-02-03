# frozen_string_literal: true

require 'models/shared_examples/vcs/having_remote.rb'

RSpec.describe VCS::Archive, type: :model do
  subject(:archive) { build_stubbed :vcs_archive }

  it_should_behave_like 'vcs: having remote' do
    let(:object) { build :vcs_archive }
  end

  describe 'associations' do
    it do
      is_expected.to belong_to(:repository).validate(false).dependent(false)
    end
  end

  describe 'aliases' do
    it 'aliases #backups to repository#file_backups' do
      expect(archive.repository).to receive(:file_backups).and_return 'backups'
      expect(archive.backups).to eq 'backups'
    end
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:file_backups).to(:repository) }
    it { is_expected.to delegate_method(:grant_read_access_to).to(:remote) }
    it { is_expected.to delegate_method(:revoke_access_from).to(:remote) }
  end

  describe 'validations' do
    subject(:archive) { build :vcs_archive }

    it do
      is_expected
        .to validate_presence_of(:repository)
        .with_message('must exist')
    end
    it do
      is_expected.to validate_presence_of(:remote_file_id)
    end

    it do
      is_expected
        .to validate_uniqueness_of(:repository_id)
        .with_message('already has an archive')
        .case_insensitive
    end
  end

  describe '#grant_public_access' do
    let(:api) { instance_double Providers::GoogleDrive::ApiConnection }

    before do
      allow(archive).to receive(:default_api_connection).and_return api
      allow(archive).to receive(:remote_file_id).and_return 'remote-archive-id'
      allow(api).to receive(:share_file_with_anyone)
    end

    it 'shares the remote archive publicly' do
      archive.grant_public_access
      expect(api)
        .to have_received(:share_file_with_anyone)
        .with('remote-archive-id', :reader)
    end
  end

  describe '#remove_public_access' do
    let(:api) { instance_double Providers::GoogleDrive::ApiConnection }

    before do
      allow(archive).to receive(:default_api_connection).and_return api
      allow(archive).to receive(:remote_file_id).and_return 'remote-archive-id'
      allow(api).to receive(:unshare_file_with_anyone)
    end

    it 'shares the remote archive publicly' do
      archive.remove_public_access
      expect(api)
        .to have_received(:unshare_file_with_anyone)
        .with('remote-archive-id')
    end
  end
end
