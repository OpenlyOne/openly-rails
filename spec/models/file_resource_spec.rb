# frozen_string_literal: true

RSpec.describe FileResource, type: :model do
  subject(:file) { build :file_resource }

  describe '.entities' do
    subject(:entities) { FileResource.entities }
    it { expect(entities.values).to include FileResources::GoogleDrive }
  end

  describe '#thumbnail_version_id' do
    it 'raises an error' do
      expect { file.thumbnail_version_id }.to raise_error(
        '#thumbnail_version_id must not be called from super class FileResource'
      )
    end
  end
end
