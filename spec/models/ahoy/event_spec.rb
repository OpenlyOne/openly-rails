# frozen_string_literal: true

RSpec.describe Ahoy::Event, type: :model do
  subject(:visit) { Ahoy::Event.new }

  describe 'associations' do
    it do
      is_expected
        .to belong_to(:visit).class_name('Ahoy::Visit').dependent(false)
    end
    it do
      is_expected
        .to belong_to(:user).class_name('Profiles::User').dependent(false)
    end
  end
end
