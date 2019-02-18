# frozen_string_literal: true

RSpec.describe Account, type: :model do
  subject(:account) { build(:account) }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  describe 'associations' do
    it { is_expected.to have_one(:user).dependent(:destroy) }
    it do
      is_expected
        .to have_many(:notifications)
        .class_name('Notification')
        .dependent(:delete_all)
    end
  end

  describe 'attributes' do
    it { is_expected.to accept_nested_attributes_for(:user) }

    it 'sets is_premium to false by default' do
      expect(account).not_to be_premium
    end
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:handle).to(:user).with_prefix(true) }
  end

  describe 'devise' do
    context 'rememberable' do
      it 'remembers the account for one week' do
        subject.save
        subject.remember_me!
        expect(subject.remember_expires_at)
          .to be_within(1.minute).of(Time.zone.now + 1.week)
      end
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:user).on(:create) }
    it { is_expected.to validate_confirmation_of(:password) }
    it { is_expected.to validate_length_of(:password).is_at_least(8) }
    it { is_expected.to validate_length_of(:password).is_at_most(128) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
  end

  describe '#notify_to(notifying_object, options = {})' do
    after { account.notify_to('object', 'options') }

    it 'calls #notify_to on ::Notification' do
      expect(::Notification).to receive(:notify_to)
        .with(account, 'object', 'options')
    end
  end
end
