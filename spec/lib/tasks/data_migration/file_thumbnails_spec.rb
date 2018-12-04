# frozen_string_literal: true

require 'lib/shared_contexts/rake.rb'

# TODO: Archive because no longer relevant as data has been migrated
RSpec.describe 'data_migration:file_thumbnails', :archived do
  include_context 'rake'

  let(:run_the_task) { subject.invoke }

  let!(:old_thumbnails) do
    build_list(:vcs_file_thumbnail, 3, file_id: nil).each do |record|
      record.save!(validate: false)
    end
  end

  before { allow(STDOUT).to receive(:puts) }

  before do
    # verify that old image is present
    old_thumbnails.each do |thumbnail|
      expect(FileThumbnailMigrator.old_image(thumbnail)).to be_present
    end
  end

  after do
    # verify that old thumbnails no longer exist
    old_thumbnails.each do |thumbnail|
      expect(VCS::Thumbnail).not_to be_exists(thumbnail.id)
    end
  end

  it 'migrates file thumbnails' do
    file1 = create :vcs_file_in_branch, thumbnail: old_thumbnails.first
    file2 = create :vcs_file_in_branch, thumbnail: old_thumbnails.first
    file3 = create :vcs_file_in_branch, thumbnail: old_thumbnails.second
    file4 = create :vcs_file_in_branch, thumbnail: old_thumbnails.second

    run_the_task

    expect(file1.reload.thumbnail.image).to be_present
    expect(file2.reload.thumbnail.image).to be_present
    expect(file1.thumbnail_id).not_to eq file2.thumbnail_id
    expect(file3.reload.thumbnail.image).to be_present
    expect(file4.reload.thumbnail.image).to be_present
    expect(file3.thumbnail_id).not_to eq file4.thumbnail_id
  end

  context 'when two versions have the same file record id' do
    let(:new_thumbnail) do
      VCS::Thumbnail.find_by(
        remote_file_id: old_thumbnail.remote_file_id,
        version_id: old_thumbnail.version_id,
        file_id: snap1.file_id
      )
    end
    let!(:snap1) { create :vcs_version, thumbnail: old_thumbnail }
    let!(:snap2) do
      create :vcs_version,
             file_id: snap1.file_id, thumbnail: old_thumbnail
    end
    let(:old_thumbnail) { old_thumbnails.first }

    it 'sets the same thumbnail on both' do
      run_the_task
      expect(snap1.reload.thumbnail_id).to eq new_thumbnail.id
      expect(snap2.reload.thumbnail_id).to eq new_thumbnail.id
    end
  end
end
