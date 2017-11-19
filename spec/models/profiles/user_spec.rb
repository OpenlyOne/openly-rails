# frozen_string_literal: true

require 'models/shared_examples/being_a_profile.rb'

RSpec.describe Profiles::User, type: :model do
  subject(:user) { build(:user) }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  it_should_behave_like 'being a profile'

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it do
      is_expected.to(
        have_many(:discussions)
          .class_name('Discussions::Base')
          .dependent(:destroy)
          .with_foreign_key(:initiator_id)
          .inverse_of(:initiator)
      )
    end
    it do
      is_expected.to(
        have_many(:replies)
          .dependent(:destroy)
          .with_foreign_key(:author_id)
          .inverse_of(:author)
      )
    end
  end

  describe 'attributes' do
    it { is_expected.to have_readonly_attribute(:account_id) }
  end

  describe 'validations' do
    it do
      is_expected.to validate_presence_of(:account).with_message 'must exist'
    end
  end

  describe '#destroy' do
    # verify that no ActiveRecord::InvalidForeignKey error is raised
    context 'when discussions exist' do
      let(:user) { create(:user) }
      before { create_list(:discussions_suggestion, 3, initiator: user) }
      it { expect { subject.destroy }.not_to raise_error }
    end
    context 'when replies exist' do
      let(:user) { create(:user) }
      before { create_list(:reply, 3, author: user) }
      it { expect { subject.destroy }.not_to raise_error }
    end
  end
end
