# frozen_string_literal: true

RSpec.describe Handle, type: :model do
  subject(:handle) { build(:handle) }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  describe 'associations' do
    it { is_expected.to belong_to(:profile) }
  end

  describe 'attributes' do
    it { is_expected.to have_readonly_attribute(:profile_id) }
    it { is_expected.to have_readonly_attribute(:profile_type) }
  end

  describe 'validations' do
    it do
      is_expected.to validate_presence_of(:profile).with_message 'must exist'
    end
    it do
      is_expected.to validate_uniqueness_of(:profile_id).scoped_to :profile_type
    end
    it do
      is_expected.to validate_inclusion_of(:profile_type).in_array %w[User]
    end
    it { is_expected.to validate_presence_of :identifier }
    it { is_expected.to validate_uniqueness_of(:identifier).case_insensitive }
  end
end
