# frozen_string_literal: true

require 'models/shared_examples/being_a_file_item.rb'

RSpec.describe FileItems::Base, type: :model do
  subject(:base) { build(:file_items_base) }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  it_should_behave_like 'being a file item'

  context 'Single Table Inheritance Mime Types' do
    subject(:first_item)  { FileItems::Base.first }
    before                { create :file_items_base, mime_type: folder_type }

    context 'when mime type is folder' do
      let(:folder_type) { 'application/vnd.google-apps.folder' }
      it { is_expected.to be_a FileItems::Folder }
    end

    context 'when mime type is document' do
      let(:folder_type) { 'application/vnd.google-apps.document' }
      it { is_expected.to be_a FileItems::File }
    end

    context 'when mime type is spreasheet' do
      let(:folder_type) { 'application/vnd.google-apps.spreasheet' }
      it { is_expected.to be_a FileItems::File }
    end

    context 'when mime type is anything else' do
      let(:folder_type) { 'some-imaginary-mime-type' }
      it { is_expected.to be_a FileItems::File }
    end

    context 'when mime type is empty' do
      let(:folder_type) { '' }
      it { is_expected.to be_a FileItems::Base }
    end
  end
end
