# frozen_string_literal: true

RSpec.describe VCS::Content, type: :model do
  subject(:content) { build :vcs_content }

  describe 'associations' do
    it { is_expected.to belong_to(:repository).dependent(false) }
    it { is_expected.to have_many(:remote_contents).dependent(:delete_all) }
  end

  describe 'downloaded?' do
    it { is_expected.not_to be_downloaded }

    context 'when plain text is blank' do
      before { content.plain_text = '' }

      it { is_expected.to be_downloaded }
    end

    context 'when plain_text is present' do
      before { content.plain_text = 'some content' }

      it { is_expected.to be_downloaded }
    end
  end
end
