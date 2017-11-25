# frozen_string_literal: true

module FileItems
  # FileItems of type folder (identified by MIME type)
  class Folder < Base
    # MUST precede children association otherwise callbacks are not executed in
    # correct order
    before_destroy :reset_parent_id_of_committed_children,
                   if: :added_since_last_commit?

    has_many :children, class_name: 'FileItems::Base',
                        foreign_key: 'parent_id',
                        dependent: :destroy,
                        inverse_of: :parent

    # The url template for generating the file's external link
    def self.external_link_template
      'https://drive.google.com/drive/folders/GID'
    end

    # Create a new child file based on a Google::Apis::DriveV3::Change instance
    def create_child_from_change(change)
      children.create(
        project_id: project_id,
        google_drive_id: change.file_id,
        mime_type: change.file.mime_type,
        version: change.file.version.to_i,
        name: change.file.name,
        modified_time: change.file.modified_time
      )
    end

    # The path to the file item's icon
    # We customize the folder icon because Google's default folder icon looks
    # sort of bland
    def icon
      'files/folder.png'
    end

    private

    # Resets the parent ID of children that have been committed
    def reset_parent_id_of_committed_children
      children
        .where
        .not(parent_id_at_last_commit: nil)
        .update_all('parent_id=parent_id_at_last_commit')
    end
  end
end
