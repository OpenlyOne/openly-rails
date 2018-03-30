# frozen_string_literal: true

RSpec.describe FileDiff, type: :model do
  describe 'scope: joins_current_or_previous_snapshot' do
    subject { scoped_query.first.id_from_query }
    let(:scoped_query) do
      FileDiff.joins_current_or_previous_snapshot
              .select('current_or_previous_snapshot.id AS id_from_query')
    end
    let!(:diff) do
      create :file_diff, current_snapshot: current_snapshot,
                         previous_snapshot: previous_snapshot
    end
    let(:current_snapshot)  { create :file_resource_snapshot }
    let(:previous_snapshot) { create :file_resource_snapshot }

    it { is_expected.to eq current_snapshot.id }

    context 'when current snapshot is nil' do
      let(:current_snapshot) { nil }
      it { is_expected.to eq previous_snapshot.id }
    end

    context 'when previous snapshot is nil' do
      let(:previous_snapshot) { nil }
      it { is_expected.to eq current_snapshot.id }
    end
  end

  describe 'scope: order_by_name_with_folders_first' do
    subject(:scoped_query)  { FileDiff.order_by_name_with_folders_first }
    let(:folders)           { scoped_query.select(&:folder?) }
    let(:files)             { scoped_query.reject(&:folder?) }

    before do
      create :file_diff,
             file_resource: create(:file_resource, :folder, name: 'XYZ')
      create :file_diff,
             file_resource: create(:file_resource, :folder, name: 'abc')
      create :file_diff,
             file_resource: create(:file_resource, name: 'HELLO')
      create :file_diff,
             file_resource: create(:file_resource, name: 'beta')
      create :file_diff,
             file_resource: create(:file_resource, name: 'zebra')
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
