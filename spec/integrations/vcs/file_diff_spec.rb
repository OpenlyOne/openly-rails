# frozen_string_literal: true

RSpec.describe VCS::FileDiff, type: :model do
  describe 'scope: joins_current_or_previous_snapshot' do
    subject { scoped_query.first.id_from_query }
    let(:scoped_query) do
      described_class.joins_current_or_previous_snapshot
                     .select('current_or_previous_snapshot.id AS id_from_query')
    end
    let!(:diff) do
      create :vcs_file_diff, new_snapshot: new_snapshot,
                             old_snapshot: old_snapshot
    end
    let(:new_snapshot)  { create :vcs_file_snapshot }
    let(:old_snapshot)  { create :vcs_file_snapshot }

    it { is_expected.to eq new_snapshot.id }

    context 'when current snapshot is nil' do
      let(:new_snapshot) { nil }
      it { is_expected.to eq old_snapshot.id }
    end

    context 'when previous snapshot is nil' do
      let(:old_snapshot) { nil }
      it { is_expected.to eq new_snapshot.id }
    end
  end

  describe 'scope: order_by_name_with_folders_first' do
    subject(:scoped_query)  { described_class.order_by_name_with_folders_first }
    let(:folders)           { scoped_query.select(&:folder?) }
    let(:files)             { scoped_query.reject(&:folder?) }

    before do
      create :vcs_file_diff,
             new_snapshot: create(:vcs_file_snapshot, :folder, name: 'XYZ')
      create :vcs_file_diff,
             new_snapshot: create(:vcs_file_snapshot, :folder, name: 'abc')
      create :vcs_file_diff,
             new_snapshot: create(:vcs_file_snapshot, name: 'HELLO')
      create :vcs_file_diff,
             new_snapshot: create(:vcs_file_snapshot, name: 'beta')
      create :vcs_file_diff,
             new_snapshot: create(:vcs_file_snapshot, name: 'zebra')
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
