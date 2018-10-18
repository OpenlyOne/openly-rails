# frozen_string_literal: true

class Project
  # The archive for storing file backups, just like a .git folder
  class Archive < ApplicationRecord
    # Associations
    belongs_to :project
    belongs_to :file_resource
    has_many :backups, class_name: 'FileResource::Backup', dependent: :destroy

    # Validations
    validates :project_id, uniqueness: { message: 'already has an archive' }

    # Set up the archive folder with the provider by creating it and granting
    # view access to the repository owner
    def setup
      raise 'Already set up' if setup_completed?

      create_external_folder
      grant_view_access_to_repository_owner
      file_resource.pull
    end

    # Return true if setup has been completed (i.e. file resource is present)
    def setup_completed?
      file_resource.present?
    end

    private

    # Creates the archive folder with the provider
    def create_external_folder
      folder = sync_adapter_class.create(
        name: "#{project.title} (Archive)",
        parent_id: 'root',
        mime_type: mime_type_class.folder
      )
      self.file_resource = file_resource_class.new(external_id: folder.id)
    end

    # Grants view access to the archive folder to the repository owner
    def grant_view_access_to_repository_owner
      api_connection_class
        .default
        .share_file(file_resource.external_id, owner_account_email, :reader)
    end

    delegate :owner, to: :project
    delegate :account, to: :owner, prefix: true
    delegate :email, to: :owner_account, prefix: true

    def api_connection_class
      "Providers::#{provider}::ApiConnection".constantize
    end

    def file_resource_class
      "FileResources::#{provider}".constantize
    end

    def mime_type_class
      "Providers::#{provider}::MimeType".constantize
    end

    def provider
      'GoogleDrive'
    end

    def sync_adapter_class
      "Providers::#{provider}::FileSync".constantize
    end
  end
end
