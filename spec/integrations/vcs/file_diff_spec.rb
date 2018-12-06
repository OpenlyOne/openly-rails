# frozen_string_literal: true

RSpec.describe VCS::FileDiff, type: :model do
  describe 'scope: joins_current_or_previous_version' do
    subject { scoped_query.first.id_from_query }
    let(:scoped_query) do
      described_class.joins_current_or_previous_version
                     .select('current_or_previous_version.id AS id_from_query')
    end
    let!(:diff) do
      create :vcs_file_diff, new_version: new_version,
                             old_version: old_version
    end
    let(:new_version)  { create :vcs_version }
    let(:old_version)  { create :vcs_version }

    it { is_expected.to eq new_version.id }

    context 'when current version is nil' do
      let(:new_version) { nil }
      it { is_expected.to eq old_version.id }
    end

    context 'when previous version is nil' do
      let(:old_version) { nil }
      it { is_expected.to eq new_version.id }
    end
  end

  describe 'scope: order_by_name_with_folders_first' do
    subject(:scoped_query)  { described_class.order_by_name_with_folders_first }
    let(:folders)           { scoped_query.select(&:folder?) }
    let(:files)             { scoped_query.reject(&:folder?) }

    before do
      create :vcs_file_diff,
             new_version: create(:vcs_version, :folder, name: 'XYZ')
      create :vcs_file_diff,
             new_version: create(:vcs_version, :folder, name: 'abc')
      create :vcs_file_diff,
             new_version: create(:vcs_version, name: 'HELLO')
      create :vcs_file_diff,
             new_version: create(:vcs_version, name: 'beta')
      create :vcs_file_diff,
             new_version: create(:vcs_version, name: 'zebra')
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

  describe '.find_by_hashed_file_id!(id)' do
    subject(:finding) { described_class.find_by_hashed_file_id!(id_to_find) }

    let(:id_to_find)  { diff.hashed_file_id }
    let!(:diff)       { create :vcs_file_diff }

    it { is_expected.to eq diff }

    context 'when no match exists' do
      before { diff.destroy }

      it { expect { finding }.to raise_error ActiveRecord::RecordNotFound }
    end

    context 'when it is being chained' do
      subject(:finding) do
        described_class.none.find_by_hashed_file_id!(id_to_find)
      end

      it 'is applied within the scope of the chain' do
        expect { finding }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end
end
