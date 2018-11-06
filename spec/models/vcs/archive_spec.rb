# frozen_string_literal: true

RSpec.describe VCS::Archive, type: :model do
  subject(:archive) { build_stubbed :vcs_archive }

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
  end

  describe 'validations' do
    subject(:archive) { build :vcs_archive }

    it do
      is_expected
        .to validate_presence_of(:repository)
        .with_message('must exist')
    end
    it do
      is_expected.to validate_presence_of(:external_id)
    end

    it do
      is_expected
        .to validate_uniqueness_of(:repository_id)
        .with_message('already has an archive')
        .case_insensitive
    end
  end
end
