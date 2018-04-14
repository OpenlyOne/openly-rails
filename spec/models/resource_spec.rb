# frozen_string_literal: true

RSpec.describe Resource, type: :model do
  subject(:resource) { build_stubbed :resource }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  describe 'associations' do
    it { is_expected.to belong_to(:owner).dependent(false) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:mime_type) }
    it do
      is_expected.to validate_presence_of(:owner).with_message('must exist')
    end
    it { is_expected.to validate_presence_of(:link) }
  end
end
