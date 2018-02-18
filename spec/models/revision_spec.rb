# frozen_string_literal: true

RSpec.describe Revision, type: :model do
  subject(:revision) { build_stubbed :revision }
  describe 'associations' do
    it { is_expected.to belong_to(:project).dependent(false) }
    it do
      is_expected
        .to belong_to(:parent)
        .class_name('Revision')
        .autosave(false)
        .dependent(false)
    end
    it do
      is_expected
        .to belong_to(:author).class_name('Profiles::User').dependent(false)
    end
  end

  describe 'attributes' do
    it { is_expected.to have_readonly_attribute(:project_id) }
    it { is_expected.to have_readonly_attribute(:parent_id) }
    it { is_expected.to have_readonly_attribute(:author_id) }
  end

  describe 'validations' do
    it { is_expected.not_to validate_presence_of(:title) }
    it { is_expected.not_to validate_presence_of(:summary) }

    context 'when is_published=true' do
      before  { revision.is_published = true }
      it      { is_expected.to validate_presence_of(:title) }
      it      { is_expected.to validate_presence_of(:summary) }
    end
  end
end
