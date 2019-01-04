# frozen_string_literal: true

RSpec.describe Profiles::Base, type: :model do
  describe 'route keys' do
    it 'should have singular route key: profile' do
      expect(subject.model_name.singular_route_key).to eq 'profile'
    end
    it 'should have route key: profiles' do
      expect(subject.model_name.route_key).to eq 'profiles'
    end
  end
end
