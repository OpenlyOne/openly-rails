# frozen_string_literal: true

require 'models/shared_examples/being_a_profile.rb'

RSpec.describe Profiles::User, type: :model do
  subject(:user) { build(:user) }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  it_should_behave_like 'being a profile' do
    subject(:profile) { user }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:visits).class_name('Ahoy::Visit') }
    it do
      is_expected
        .to have_many(:contributions)
        .with_foreign_key(:creator_id)
        .dependent(:destroy)
    end
  end

  describe 'attributes' do
    it { is_expected.to have_readonly_attribute(:account_id) }
  end

  describe 'validations' do
    it do
      is_expected.to validate_presence_of(:account).with_message 'must exist'
    end
  end

  describe '#premium_account?' do
    context 'when account is premium' do
      before { user.account = build_stubbed(:account, :premium) }

      it { is_expected.to be_premium_account }
    end

    context 'when account is not premium' do
      before { user.account = build_stubbed(:account, :free) }

      it { is_expected.not_to be_premium_account }
    end
  end
end
