# frozen_string_literal: true

RSpec.describe Ahoy::Visit, type: :model do
  subject(:visit) { Ahoy::Visit.new }

  describe 'associations' do
    it do
      is_expected
        .to have_many(:events).class_name('Ahoy::Event').dependent(:delete_all)
    end
    it do
      is_expected
        .to belong_to(:user).class_name('Profiles::User').dependent(false)
    end
  end
end
