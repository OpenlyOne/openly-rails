# frozen_string_literal: true

RSpec.describe VCS::RemoteContent, type: :model do
  subject(:remote_content) { build_stubbed :vcs_remote_content }

  describe 'associations' do
    it { is_expected.to belong_to(:repository).dependent(false) }
    it { is_expected.to belong_to(:content).dependent(false) }
  end

  describe 'validations' do
    subject(:remote_content) { build :vcs_remote_content }

    it do
      is_expected
        .to validate_presence_of(:repository).with_message('must exist')
    end
    it do
      is_expected.to validate_presence_of(:content).with_message('must exist')
    end
    it { is_expected.to validate_presence_of(:remote_file_id) }
    it { is_expected.to validate_presence_of(:remote_content_version_id) }

    it do
      is_expected
        .to validate_uniqueness_of(:remote_file_id)
        .scoped_to(%i[repository_id remote_content_version_id])
    end
  end
end
