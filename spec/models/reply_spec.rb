# frozen_string_literal: true

RSpec.describe Reply, type: :model do
  subject(:contribution) { build_stubbed :reply }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  describe 'associations' do
    it do
      is_expected
        .to belong_to(:author).class_name('Profiles::User').dependent(false)
    end
    it { is_expected.to belong_to(:contribution).dependent(false) }
  end

  describe 'validations' do
    it do
      is_expected.to validate_presence_of(:author).with_message('must exist')
    end
    it do
      is_expected
        .to validate_presence_of(:contribution).with_message('must exist')
    end
    it { is_expected.to validate_presence_of(:content) }
  end
end
