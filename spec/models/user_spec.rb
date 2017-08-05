# frozen_string_literal: true

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it do
      is_expected.to have_one(:handle).dependent(:destroy).inverse_of :profile
    end
  end

  describe 'attributes' do
    it { is_expected.to have_readonly_attribute(:account_id) }
  end

  describe 'validations' do
    it do
      is_expected.to validate_presence_of(:account).with_message 'must exist'
    end
    it { is_expected.to validate_presence_of(:handle).on(:create) }
    it { is_expected.to validate_presence_of(:name) }
  end
end
