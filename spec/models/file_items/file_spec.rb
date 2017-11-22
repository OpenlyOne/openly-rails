# frozen_string_literal: true

require 'models/shared_examples/being_a_file_item.rb'

RSpec.describe FileItems::File, type: :model do
  subject(:file) { build(:file_items_file) }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  it_should_behave_like 'being a file item'

  describe '#external_link' do
    subject(:method) { file.external_link }

    context "when google drive id is 'abc'" do
      before { file.google_drive_id = 'abc' }
      it { is_expected.to eq 'https://drive.google.com/file/d/abc' }
    end

    context "when google drive id is '1234'" do
      before { file.google_drive_id = '1234' }
      it { is_expected.to eq 'https://drive.google.com/file/d/1234' }
    end
    context 'when google drive id is nil' do
      before { file.google_drive_id = nil }
      it { is_expected.to eq nil }
    end
  end
end
