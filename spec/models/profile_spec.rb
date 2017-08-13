# frozen_string_literal: true

RSpec.describe Profile, type: :model do
  describe '.find' do
    context 'when profile with handle exists' do
      let!(:profile) { create(:user) }

      it 'returns the profile' do
        expect(Profile.find(profile.handle.identifier)).to eq profile
      end
    end

    context 'when profile with handle does not exist' do
      let!(:profile) { build(:user) }

      it 'raises ActiveRecord::RecordNotFound' do
        expect do
          Profile.find(profile.handle.identifier)
        end.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end
end
