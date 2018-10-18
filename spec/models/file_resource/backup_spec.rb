# frozen_string_literal: true

RSpec.describe FileResource::Backup, type: :model do
  subject(:backup) { build_stubbed :file_resource_backup }

  describe 'associations' do
    it do
      is_expected
        .to belong_to(:file_resource_snapshot)
        .class_name('FileResource::Snapshot')
        .validate(false)
        .dependent(false)
    end
    it do
      is_expected
        .to belong_to(:archive)
        .class_name('Project::Archive')
        .validate(false)
        .dependent(false)
    end
    it do
      is_expected.to belong_to(:file_resource).validate(false).dependent(false)
    end
  end

  describe 'validations' do
    subject(:backup) { build :file_resource_backup }

    it do
      is_expected
        .to validate_presence_of(:file_resource_snapshot)
        .with_message('must exist')
    end
    it do
      is_expected
        .to validate_presence_of(:archive).with_message('must exist')
    end

    it do
      is_expected
        .to validate_uniqueness_of(:file_resource_snapshot_id)
        .with_message('already has a backup')
        .case_insensitive
    end
  end
end
