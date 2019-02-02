# frozen_string_literal: true

RSpec.describe VCS::Version, type: :model do
  # describe 'scope: with_provider_id' do
  #   subject(:versions) { described_class.with_provider_id }
  #   let!(:version1)    { create :file_resource_version }
  #   let!(:version2)    { create :file_resource_version }
  #
  #   it 'fetches provider id' do
  #     expect(versions.first['provider_id']).to eq version1.provider_id
  #     expect(versions.second['provider_id']).to eq version2.provider_id
  #   end
  # end

  describe 'scope: order_by_name_with_folders_first' do
    subject(:scoped_query) { described_class.order_by_name_with_folders_first }
    let(:folders) { scoped_query.select(&:folder?) }
    let(:files)   { scoped_query.reject(&:folder?) }

    before do
      create :vcs_version, :folder, name: 'abc'
      create :vcs_version, :folder, name: 'XYZ'
      create :vcs_version
      create :vcs_version
      create :vcs_version
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
    let(:content)         { file_in_branch.content }
    let(:attributes) do
      attributes_for(:vcs_version,
                     file: file, file_id: file.id,
                     content: content, content_id: content.id)
    end

    it 'creates a new version' do
      expect { subject }.to change(described_class, :count).by(1)
    end

    describe 'when version already exists' do
      let!(:existing_version) { described_class.for(attributes) }

      it 'does not create a new version' do
        expect { subject }
          .not_to change(described_class, :count)
      end

      context 'when supplemental attributes change' do
        let(:thumbnail) { create :vcs_file_thumbnail }
        let(:version)   { described_class.order(:created_at).first }
        before          { attributes[:thumbnail_id] = thumbnail.id }

        it 'updates thumbnail on the version' do
          expect { subject }
            .to change { existing_version.reload.thumbnail_id }.from(nil)
        end
      end
    end
  end

  describe '#version!' do
    subject       { version.version! }
    let(:version) { create :vcs_version }

    before { version.name = 'new-name' }

    it 'creates a new version' do
      expect { subject }.to change(described_class, :count).by(1)
    end

    it 'acquires ID of new version and reloads' do
      subject
      expect(version).to eq described_class.order(:created_at).last
      expect(version).not_to be_changed
    end
  end
end
