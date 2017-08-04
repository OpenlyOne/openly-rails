# frozen_string_literal: true

RSpec.describe Account, type: :model do
  subject(:account) { build(:account) }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  describe 'associations' do
    it { is_expected.to have_one(:user).dependent(:destroy) }
  end

  describe 'attributes' do
    it { is_expected.to accept_nested_attributes_for(:user) }
    it { is_expected.to have_readonly_attribute(:email) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:user).on(:create) }
    it { is_expected.to validate_confirmation_of(:password) }
    it { is_expected.to validate_length_of(:password).is_at_least(8) }
    it { is_expected.to validate_length_of(:password).is_at_most(128) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
  end
end
