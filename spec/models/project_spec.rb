# frozen_string_literal: true

RSpec.describe Project, type: :model do
  subject(:project) { build(:project) }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  describe 'associations' do
    it { is_expected.to belong_to(:owner) }
  end

  describe 'attributes' do
    it { is_expected.to have_readonly_attribute(:owner_id) }
    it { is_expected.to have_readonly_attribute(:owner_type) }
  end

  describe 'validations' do
    it do
      is_expected.to validate_presence_of(:owner).with_message 'must exist'
    end
    it do
      is_expected.to validate_inclusion_of(:owner_type).in_array %w[User]
    end
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_most(50) }

    context 'when validating slug' do
      it do
        is_expected
          .to validate_uniqueness_of(:slug)
          .case_insensitive
          .scoped_to(:owner_type, :owner_id)
      end
      it { is_expected.to validate_presence_of(:slug) }
      it { is_expected.to validate_length_of(:slug).is_at_most(50) }

      it 'special characters are invalid' do
        project.slug = 'a*<>$@/r?!'
        is_expected.to be_invalid
      end

      it 'a dash at the beginning is invalid' do
        project.slug = '-' + project.slug
        is_expected.to be_invalid
      end

      it 'a dash at the end is invalid' do
        project.slug += '-'
        is_expected.to be_invalid
      end
    end
  end

  describe '#title=' do
    it 'strips whitespace' do
      project.title = '   lots of whitespace     '
      expect(project.title).to eq 'lots of whitespace'
    end

    it 'leaves nil unchanged' do
      project.title = nil
      expect(project.title).to eq nil
    end
  end
end
