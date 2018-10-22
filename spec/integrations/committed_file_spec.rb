# frozen_string_literal: true

RSpec.describe CommittedFile, type: :model do
  subject(:file) { build(:committed_file) }

  describe 'validation: file resource snapshot must belong to file resource' do
    let(:file_resource) { file.file_resource }
    before              { file.file_resource_snapshot = snapshot }

    context 'when file resource snapshot belongs to file resource' do
      let(:snapshot) { file_resource.current_snapshot }
      it             { is_expected.to be_valid }
    end

    context 'when file resource snapshot does not belong to file resource' do
      let(:snapshot) { create(:file_resource_snapshot) }
      it             { is_expected.to be_invalid }
    end
  end

  describe 'scope: order_by_name_with_folders_first' do
    subject(:scoped_query) { described_class.order_by_name_with_folders_first }
    let(:scoped_query_snapshots) { scoped_query.map(&:file_resource_snapshot) }
    let(:folders) { scoped_query_snapshots.select(&:folder?) }
    let(:files)   { scoped_query_snapshots.reject(&:folder?) }

    before do
      create :committed_file,
             file_resource: create(:file_resource, :folder, name: 'XYZ')
      create :committed_file,
             file_resource: create(:file_resource, :folder, name: 'abc')
      create :committed_file,
             file_resource: create(:file_resource, name: 'HELLO')
      create :committed_file,
             file_resource: create(:file_resource, name: 'beta')
      create :committed_file,
             file_resource: create(:file_resource, name: 'zebra')
    end

    it 'returns folders first' do
      expect(scoped_query_snapshots.first).to be_folder
      expect(scoped_query_snapshots.second).to be_folder
    end

    it 'returns elements in case insensitive alphabetical order' do
      expect(folders).to eq(folders.sort_by { |file| file.name.downcase })
      expect(files).to eq(files.sort_by { |file| file.name.downcase })
    end
  end
end
