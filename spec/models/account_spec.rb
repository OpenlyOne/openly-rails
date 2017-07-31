# frozen_string_literal: true

RSpec.describe Account, type: :model do
  subject(:account) { build(:account) }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  describe 'validations' do
    it { is_expected.to validate_confirmation_of(:password) }
    it { is_expected.to validate_length_of(:password).is_at_least(8) }
    it { is_expected.to validate_length_of(:password).is_at_most(128) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
  end
end
