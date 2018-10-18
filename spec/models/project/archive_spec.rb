# frozen_string_literal: true

RSpec.describe Project::Archive, type: :model do
  subject(:archive) { build_stubbed :project_archive }

  describe 'associations' do
    it { is_expected.to belong_to(:project).validate(false).dependent(false) }
    it do
      is_expected.to belong_to(:file_resource).validate(false).dependent(false)
    end
  end

  describe 'validations' do
    subject(:archive) { build :project_archive }

    it do
      is_expected.to validate_presence_of(:project).with_message('must exist')
    end
    it do
      is_expected
        .to validate_presence_of(:file_resource).with_message('must exist')
    end

    it do
      is_expected
        .to validate_uniqueness_of(:project_id)
        .with_message('already has an archive')
        .case_insensitive
    end
  end
end
