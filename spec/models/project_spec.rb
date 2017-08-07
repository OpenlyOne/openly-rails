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
  end
end
