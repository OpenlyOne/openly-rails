module VCS
  class Archive < ApplicationRecord
    belongs_to :repository

    # TODO: Make name & owners updatable

    attr_accessor :name, :owner_account_email

    # Validations
    validates :repository_id, uniqueness: { message: 'already has an archive' }
    validates :external_id, presence: true

    def backups
      repository.file_backups
    end

    # Set up the archive folder with the provider by creating it and granting
    # view access to the repository owner
    def setup
      raise 'Already set up' if setup_completed?

      create_external_folder
      grant_view_access_to_repository_owner
    end

    # Return true if setup has been completed (i.e. file resource is present)
    def setup_completed?
      external_id.present?
    end

    private

    # Creates the archive folder with the provider
    def create_external_folder
      folder = sync_adapter_class.create(
        name: "#{name} (Archive)",
        parent_id: 'root',
        mime_type: mime_type_class.folder
      )
      self.external_id = folder.id
    end

    # Grants view access to the archive folder to the repository owner
    def grant_view_access_to_repository_owner
      api_connection_class
        .default
        .share_file(external_id, owner_account_email, :reader)
    end

    def api_connection_class
      "Providers::#{provider}::ApiConnection".constantize
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
