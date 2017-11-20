# frozen_string_literal: true

require 'models/shared_examples/being_a_file_item.rb'

RSpec.describe FileItems::Folder, type: :model do
  subject(:folder) { build(:file_items_folder) }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  it_should_behave_like 'being a file item'

  describe 'associations' do
    it do
      is_expected.to(
        have_many(:children)
          .class_name('FileItems::Base')
          .dependent(:destroy)
          .with_foreign_key(:parent_id)
          .inverse_of(:parent)
      )
    end
  end
end
