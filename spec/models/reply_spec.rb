# frozen_string_literal: true

RSpec.describe Reply, type: :model do
  subject(:reply) { build(:reply) }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  describe 'associations' do
    it { is_expected.to belong_to(:author).class_name('User') }
    it { is_expected.to belong_to(:discussion).class_name('Discussions::Base') }
  end

  describe 'validations' do
    it do
      is_expected.to validate_presence_of(:author).with_message 'must exist'
    end
    it do
      is_expected.to validate_presence_of(:discussion).with_message 'must exist'
    end
    it { is_expected.to validate_presence_of(:content) }
  end
end
