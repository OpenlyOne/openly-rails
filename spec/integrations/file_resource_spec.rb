# frozen_string_literal: true

RSpec.describe FileResource, type: :model do
  describe 'scope: order_by_name_with_folders_first' do
    subject(:scoped_query)  { FileResource.order_by_name_with_folders_first }
    let(:folders)           { scoped_query.select(&:folder?) }
    let(:files)             { scoped_query.reject(&:folder?) }

    before do
      create :file_resource, :folder, name: 'XYZ'
      create :file_resource, :folder, name: 'abc'
      create :file_resource, name: 'HELLO'
      create :file_resource, name: 'beta'
      create :file_resource, name: 'zebra'
    end

    it 'returns folders first' do
      expect(scoped_query.first).to be_folder
      expect(scoped_query.second).to be_folder
    end

    it 'returns elements in case insensitive alphabetical order' do
      expect(folders).to eq(folders.sort_by { |file| file.name.downcase })
      expect(files).to eq(files.sort_by { |file| file.name.downcase })
    end
  end
end
