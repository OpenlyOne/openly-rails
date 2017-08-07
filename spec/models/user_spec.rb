# frozen_string_literal: true

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  describe 'route keys' do
    it 'should have singural route key: profile' do
      expect(user.model_name.singular_route_key).to eq 'profile'
    end
    it 'should have route key: profiles' do
      expect(user.model_name.route_key).to eq 'profiles'
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it do
      is_expected.to have_one(:handle).dependent(:destroy).inverse_of :profile
    end
    it do
      is_expected.to have_many(:projects).dependent(:destroy).inverse_of :owner
    end
  end

  describe 'attributes' do
    it { is_expected.to accept_nested_attributes_for(:handle) }
    it { is_expected.to have_readonly_attribute(:account_id) }
  end

  describe 'validations' do
    it do
      is_expected.to validate_presence_of(:account).with_message 'must exist'
    end
    it { is_expected.to validate_presence_of(:handle).on(:create) }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe '#to_param' do
    it 'returns the handle (username)' do
      expect(user.to_param).to eq user.handle.identifier
    end

    context 'when handle is nil' do
      before { user.handle = nil }

      it 'returns nil' do
        expect(user.to_param).to eq nil
      end
    end
  end

  describe '#username' do
    it 'returns the identifier of the handle' do
      expect(user.username).to eq user.handle.identifier
    end

    context 'when handle is nil' do
      before { user.handle = nil }

      it 'returns nil' do
        expect(user.username).to eq nil
      end
    end
  end
end
