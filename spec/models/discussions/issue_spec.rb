# frozen_string_literal: true

require 'models/shared_examples/being_a_discussion.rb'

RSpec.describe Discussions::Issue, type: :model do
  subject(:issue) { build :discussions_issue }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  it_should_behave_like 'being a discussion', @metadata[:described_class] do
    let(:url_type) { 'issues' }
  end
end
