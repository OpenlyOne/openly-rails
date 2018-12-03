# frozen_string_literal: true

RSpec.describe VCS::FileSnapshot, type: :model do
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
    subject               { described_class.for(attributes) }
    let!(:file_in_branch) { create :vcs_file_in_branch }
    let(:file)            { file_in_branch.file }
    let(:attributes) do
      attributes_for(:vcs_file_snapshot, file: file, file_id: file.id)
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
