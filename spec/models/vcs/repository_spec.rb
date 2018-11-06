# frozen_string_literal: true

RSpec.describe VCS::Repository, type: :model do
  subject(:repository) { build_stubbed :vcs_repository }

  describe 'associations' do
    it { is_expected.to have_many(:branches).dependent(:destroy) }
    it { is_expected.to have_one(:archive).dependent(:destroy) }
    it { is_expected.to have_many(:file_records).dependent(:destroy) }
    it do
      is_expected
        .to have_many(:file_snapshots)
        .through(:file_records)
        .dependent(false)
    end
    it do
      is_expected
        .to have_many(:file_backups)
        .through(:file_snapshots)
        .source(:backup)
        .dependent(false)
    end
  end
end
