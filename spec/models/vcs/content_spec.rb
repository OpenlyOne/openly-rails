# frozen_string_literal: true

RSpec.describe VCS::Content, type: :model do
  subject { build :vcs_content }

  describe 'associations' do
    it { is_expected.to belong_to(:repository).dependent(false) }
    it { is_expected.to have_many(:remote_contents).dependent(:delete_all) }
  end
end
