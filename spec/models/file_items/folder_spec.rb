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

  describe '#external_link' do
    subject(:method) { folder.external_link }

    context "when google drive id is 'abc'" do
      before { folder.google_drive_id = 'abc' }
      it { is_expected.to eq 'https://drive.google.com/drive/folders/abc' }
    end

    context "when google drive id is '1234'" do
      before { folder.google_drive_id = '1234' }
      it { is_expected.to eq 'https://drive.google.com/drive/folders/1234' }
    end
    context 'when google drive id is nil' do
      before { folder.google_drive_id = nil }
      it { is_expected.to eq nil }
    end
  end

  describe '#icon' do
    it { expect(subject.icon).to eq('files/folder.png') }
  end
end
