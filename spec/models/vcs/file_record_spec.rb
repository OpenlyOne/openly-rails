# frozen_string_literal: true

RSpec.describe VCS::FileRecord, type: :model do
  subject(:file_record) { build_stubbed :vcs_file_record }

  describe 'associations' do
    it { is_expected.to belong_to(:repository).dependent(false) }
    it { is_expected.to have_many(:file_thumbnails).dependent(:destroy) }
    it do
      is_expected
        .to have_many(:repository_branches)
        .through(:repository)
        .source(:branches)
        .dependent(false)
    end
    it { is_expected.to have_many(:file_snapshots).dependent(:destroy) }
    it do
      is_expected
        .to have_many(:file_snapshots_of_children)
        .class_name('VCS::FileSnapshot')
        .with_foreign_key(:file_record_parent_id)
        .dependent(:destroy)
    end
  end
end
