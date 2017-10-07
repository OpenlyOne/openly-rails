# frozen_string_literal: true

require 'models/shared_examples/being_a_discussion.rb'

RSpec.describe Discussions::Suggestion, type: :model do
  subject(:suggestion) { build :discussions_suggestion }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  it_should_behave_like 'being a discussion', @metadata[:described_class]
end
