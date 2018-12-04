# frozen_string_literal: true

RSpec.describe VCS::File, type: :model do
  subject(:file) { build_stubbed :vcs_file }

  describe 'associations' do
    it { is_expected.to belong_to(:repository).dependent(false) }
    it { is_expected.to have_many(:thumbnails).dependent(:destroy) }
    it do
      is_expected
        .to have_many(:repository_branches)
        .through(:repository)
        .source(:branches)
        .dependent(false)
    end
    it { is_expected.to have_many(:versions).dependent(:destroy) }
    it do
      is_expected
        .to have_many(:versions_of_children)
        .class_name('VCS::Version')
        .with_foreign_key(:parent_id)
        .dependent(:destroy)
    end
  end
end
