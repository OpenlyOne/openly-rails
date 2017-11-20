# frozen_string_literal: true

require 'models/shared_examples/being_a_file_item.rb'

RSpec.describe FileItems::File, type: :model do
  subject(:file) { build(:file_items_file) }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  it_should_behave_like 'being a file item'
end
