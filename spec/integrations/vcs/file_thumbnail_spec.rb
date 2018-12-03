# frozen_string_literal: true

RSpec.describe VCS::FileThumbnail, type: :model do
  describe 'attachment path for image' do
    subject               { thumbnail.image.path }
    let(:thumbnail)       { create :vcs_file_thumbnail }
    let(:file_id)         { thumbnail.file_id }
    let(:remote_file_id)  { thumbnail.remote_file_id }
    let(:version_id)      { thumbnail.version_id }

    it 'interpolates correctly' do
      is_expected.to start_with("#{Rails.root}/public/spec/system")
      is_expected.to match(
        %r{vcs/file_thumbnails/#{file_id}/
           #{remote_file_id}/#{version_id}/\w+.png$}x
      )
    end
  end

  describe 'attachment url for image' do
    subject               { thumbnail.image.url }
    let(:thumbnail)       { create :vcs_file_thumbnail }
    let(:file_id)         { thumbnail.file_id }
    let(:remote_file_id)  { thumbnail.remote_file_id }
    let(:version_id)      { thumbnail.version_id }

    it 'interpolates correctly' do
      is_expected.to start_with('/spec/system')
      is_expected.to match(
        %r{vcs/file_thumbnails/#{file_id}/
           #{remote_file_id}/#{version_id}/\w+.png}x
      )
    end
  end

  describe 'fallback path for image' do
    subject(:url)   { thumbnail.image.url(:original, timestamp: false) }
    let(:thumbnail) { described_class.new }

    it 'is a valid path' do
      expect(File).to be_exists("#{Rails.root}/public#{url}")
    end
  end

  describe '.preload_for(objects)' do
    let(:file1) { create :vcs_file_in_branch, :with_thumbnail }
    let(:file2) { create :vcs_file_in_branch, :with_thumbnail }
    let(:file3) { create :vcs_file_in_branch, :with_thumbnail }

    before { [file1, file2, file3].each(&:reload) }

    it 'preloads all thumbnails' do
      expect(file1.association(:thumbnail)).not_to be_loaded
      expect(file2.association(:thumbnail)).not_to be_loaded
      expect(file3.association(:thumbnail)).not_to be_loaded

      described_class.preload_for([file1, file2, file3])

      expect(file1.association(:thumbnail)).to be_loaded
      expect(file2.association(:thumbnail)).to be_loaded
      expect(file3.association(:thumbnail)).to be_loaded
    end
  end
end
