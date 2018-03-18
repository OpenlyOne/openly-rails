# frozen_string_literal: true

RSpec.describe FileResource::Thumbnail, type: :model do
  describe 'attachment path for image' do
    subject           { thumbnail.image.path }
    let(:thumbnail)   { create :file_resource_thumbnail }
    let(:external_id) { thumbnail.external_id }
    let(:version_id)  { thumbnail.version_id }

    it 'interpolates correctly' do
      is_expected.to start_with("#{Rails.root}/public/spec/system")
      is_expected.to match(
        %r{file_resource/thumbnails/0/#{external_id}/#{version_id}/\w+.png$}
      )
    end
  end

  describe 'attachment url for image' do
    subject           { thumbnail.image.url }
    let(:thumbnail)   { create :file_resource_thumbnail }
    let(:external_id) { thumbnail.external_id }
    let(:version_id)  { thumbnail.version_id }

    it 'interpolates correctly' do
      is_expected.to start_with('/spec/system')
      is_expected.to match(
        %r{file_resource/thumbnails/0/#{external_id}/#{version_id}/\w+.png}
      )
    end
  end

  describe 'fallback path for image' do
    subject(:url)   { thumbnail.image.url(:original, timestamp: false) }
    let(:thumbnail) { FileResource::Thumbnail.new }

    it 'is a valid path' do
      expect(File).to be_exists("#{Rails.root}/public#{url}")
    end
  end
end
