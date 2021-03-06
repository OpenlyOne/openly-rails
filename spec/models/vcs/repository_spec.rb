# frozen_string_literal: true

RSpec.describe VCS::Repository, type: :model do
  subject(:repository) { build_stubbed :vcs_repository }

  describe 'associations' do
    it { is_expected.to have_many(:branches).dependent(:destroy) }
    it { is_expected.to have_one(:archive).dependent(:destroy) }
    it { is_expected.to have_many(:files).dependent(:destroy) }
    it do
      is_expected
        .to have_many(:file_versions)
        .through(:files)
        .dependent(false)
    end
    it do
      is_expected
        .to have_many(:file_backups)
        .through(:file_versions)
        .source(:backup)
        .dependent(false)
    end
    it { is_expected.to have_many(:contents).dependent(:destroy) }
    it { is_expected.to have_many(:remote_contents).dependent(:delete_all) }
  end
end
