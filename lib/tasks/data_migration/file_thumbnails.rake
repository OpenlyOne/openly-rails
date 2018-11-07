# frozen_string_literal: true

# Migrate file thumbnails from singe source to multi source model by adding a
# file record ID and duplicating thumbnails once for each repository
# rubocop:disable Metrics/BlockLength
desc 'Data Migration: Migrate file thumbnails (single to multi-source)'
namespace :data_migration do
  task file_thumbnails: :environment do
    VCS::FileThumbnail.reset_column_information

    thumbnails_to_migrate = VCS::FileThumbnail.where(file_record_id: nil)

    puts "Migrating #{thumbnails_to_migrate.count} thumbnails"

    ActiveRecord::Base.transaction do
      thumbnails_to_migrate.find_each do |old_thumbnail|
        puts ".Migrating #{old_thumbnail.id}"

        snapshots = VCS::FileSnapshot.where(thumbnail: old_thumbnail)
        staged_files = VCS::StagedFile.where(thumbnail: old_thumbnail)

        puts "..In use by #{snapshots.count + staged_files.count} records"

        (snapshots + staged_files).each do |record|
          file_record_id = record.file_record_id

          new_thumbnail = VCS::FileThumbnail.find_or_initialize_by(
            external_id: old_thumbnail.external_id,
            version_id: old_thumbnail.version_id,
            file_record_id: file_record_id
          )

          old_image = FileThumbnailMigrator.old_image(old_thumbnail)

          if new_thumbnail.new_record? && old_image.present?
            new_thumbnail.update!(image: old_image)
          end

          puts "..Record with FRID #{file_record_id} gets new "\
               "thumbnail ID #{new_thumbnail.id}"

          record.update_column(:thumbnail_id, new_thumbnail.id)

          puts '..Done'
        end
      end

      puts 'Deleting old file thumbnails'

      thumbnails_to_migrate.destroy_all
    end
  end
end
# rubocop:enable Metrics/BlockLength

# Helper methods for file thumbnail migration
module FileThumbnailMigrator
  def self.old_image_path(thumbnail)
    Paperclip::Interpolations
      .interpolate(old_image_path_string, thumbnail.image, :original)
  end

  def self.old_image_path_string
    ':attachment_path/:class/' \
    ':external_id/:version_id/' \
    ':hash.:content_type_extension'
  end

  def self.old_image(thumbnail)
    File.new(old_image_path(thumbnail))
  rescue Errno::ENOENT
    nil
  end
end
