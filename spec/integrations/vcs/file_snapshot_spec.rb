# frozen_string_literal: true

RSpec.describe VCS::FileSnapshot, type: :model do
  xdescribe 'scope: where_current_snapshot_is_nil' do
    subject { described_class.where_current_snapshot_is_nil }

    let!(:files_to_delete)          { create_list :file_resource, 2 }
    let!(:other_files)              { create_list :file_resource, 2 }
    let!(:without_current_snapshot) { files_to_delete.map(&:current_snapshot) }

    before do
      files_to_delete.each do |file|
        file.update!(is_deleted: true)
      end
    end

    it { is_expected.to match_array without_current_snapshot }
  end

  xdescribe 'scope: where_current_snapshot_parent(parent)' do
    subject { described_class.where_current_snapshot_parent(parent) }

    let(:parent)          { create :file_resource }
    let!(:in_parent)      { create_list :file_resource, 2, parent: parent }
    let!(:not_in_parent)  { create_list :file_resource, 2 }
    let!(:snapshot1)      { in_parent[0].current_snapshot }
    let!(:snapshot2)      { in_parent[1].current_snapshot }

    before { in_parent[0].update(name: 'new name') }

    let(:snapshot3) { in_parent[0].current_snapshot }

    it { is_expected.to contain_exactly snapshot1, snapshot2, snapshot3 }
  end

  xdescribe 'scope: of_revision(revision)' do
    subject         { described_class.of_revision(revision) }
    let(:revision)  { create :revision }
    let(:snapshot1) { create :file_resource_snapshot }
    let(:snapshot2) { create :file_resource_snapshot }
    let(:snapshot3) { create :file_resource_snapshot }
    let(:snapshot4) { create :file_resource_snapshot }
    let(:file1)     { snapshot1.file_resource }
    let(:file2)     { snapshot2.file_resource }
    let(:file3)     { snapshot3.file_resource }
    let(:file4)     { snapshot4.file_resource }

    before do
      create :committed_file, revision: revision, file_resource: file1,
                              file_resource_snapshot: snapshot1
      create :committed_file, revision: revision, file_resource: file2,
                              file_resource_snapshot: snapshot2
      create :committed_file, file_resource: file3,
                              file_resource_snapshot: snapshot3
      create :committed_file, file_resource: file4,
                              file_resource_snapshot: snapshot4
    end

    it { is_expected.to contain_exactly snapshot1, snapshot2 }
  end

  # describe 'scope: with_provider_id' do
  #   subject(:snapshots) { described_class.with_provider_id }
  #   let!(:snapshot1)    { create :file_resource_snapshot }
  #   let!(:snapshot2)    { create :file_resource_snapshot }
  #
  #   it 'fetches provider id' do
  #     expect(snapshots.first['provider_id']).to eq snapshot1.provider_id
  #     expect(snapshots.second['provider_id']).to eq snapshot2.provider_id
  #   end
  # end

  describe 'scope: order_by_name_with_folders_first' do
    subject(:scoped_query) { described_class.order_by_name_with_folders_first }
    let(:folders) { scoped_query.select(&:folder?) }
    let(:files)   { scoped_query.reject(&:folder?) }

    before do
      create :vcs_file_snapshot, :folder, name: 'abc'
      create :vcs_file_snapshot, :folder, name: 'XYZ'
      create :vcs_file_snapshot
      create :vcs_file_snapshot
      create :vcs_file_snapshot
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

  describe '.for(attributes)' do
    subject           { described_class.for(attributes) }
    let!(:file)       { create :vcs_staged_file }
    let(:file_record) { file.file_record }
    let(:attributes) do
      attributes_for(:vcs_file_snapshot,
                     file_record: file_record, file_record_id: file_record.id)
    end

    it 'creates a new snapshot' do
      expect { subject }.to change(described_class, :count).by(1)
    end

    describe 'when snapshot already exists' do
      let!(:existing_snapshot) { described_class.for(attributes) }

      it 'does not create a new snapshot' do
        expect { subject }
          .not_to change(described_class, :count)
      end

      context 'when supplemental attributes change' do
        let(:thumbnail) { create :vcs_file_thumbnail }
        let(:snapshot)  { described_class.order(:created_at).first }
        before          { attributes[:thumbnail_id] = thumbnail.id }

        it 'updates thumbnail on the snapshot' do
          expect { subject }
            .to change { existing_snapshot.reload.thumbnail_id }.from(nil)
        end
      end
    end
  end

  describe '#snapshot!' do
    subject         { snapshot.snapshot! }
    let(:snapshot)  { create :vcs_file_snapshot }

    before { snapshot.name = 'new-name' }

    it 'creates a new snapshot' do
      expect { subject }.to change(described_class, :count).by(1)
    end

    it 'acquires ID of new snapshot and reloads' do
      subject
      expect(snapshot).to eq described_class.order(:created_at).last
      expect(snapshot).not_to be_changed
    end
  end
end
