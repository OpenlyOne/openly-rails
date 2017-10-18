# frozen_string_literal: true

RSpec.shared_examples 'being a profile' do
  describe 'route keys' do
    it 'should have singular route key: profile' do
      expect(subject.model_name.singular_route_key).to eq 'profile'
    end
    it 'should have route key: profiles' do
      expect(subject.model_name.route_key).to eq 'profiles'
    end
  end

  describe 'associations' do
    it do
      is_expected.to have_one(:handle).dependent(:destroy).inverse_of :profile
    end
    it do
      is_expected.to have_many(:projects).dependent(:destroy).inverse_of :owner
    end
  end

  describe 'attributes' do
    it { is_expected.to accept_nested_attributes_for(:handle) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:handle).on(:create) }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe '#to_param' do
    it 'returns the handle (identifier)' do
      expect(subject.to_param).to eq subject.handle.identifier
    end

    context 'when handle is nil' do
      before { subject.handle = nil }

      it 'returns nil' do
        expect(subject.to_param).to eq nil
      end
    end
  end
end
