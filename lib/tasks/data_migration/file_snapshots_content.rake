# frozen_string_literal: true

# Migrate file snapshots to use VCS::Content and VCS::RemoteContent instead of
# storing external ID and content version directly on the snapshot. Using
# VCS::Content will allow us to map several remote files to the same content
# instance (useful for restoring, branching, and merging).
desc 'Data Migration: Migrate file snapshots to use VCS::Content'
namespace :data_migration do
  task file_snapshots_content: :environment do
    VCS::FileSnapshot.reset_column_information

    snapshots_to_migrate = VCS::FileSnapshot.where(content_id: nil)

    puts "Migrating #{snapshots_to_migrate.count} snapshots"

    ActiveRecord::Base.transaction do
      snapshots_to_migrate.find_each do |snapshot|
        puts ".Migrating #{snapshot.id}"

        # build VCS::Content
        content = VCS::Content.new(
          repository: snapshot.repository
        )

        # create VCS::RemoteContent
        remote_content =
          VCS::RemoteContent
          .create_with(content: content)
          .find_or_create_by!(
            repository: snapshot.repository,
            remote_file_id: snapshot.external_id,
            remote_content_version_id: snapshot.content_version
          )

        content = remote_content.content

        # update column
        puts "..New content ID #{content.id}"

        snapshot.update_column(:content_id, content.id)

        puts '..Done'
      end
    end
  end
end
