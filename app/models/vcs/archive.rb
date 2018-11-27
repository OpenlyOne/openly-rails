# frozen_string_literal: true

module VCS
  # The archive for storing file backups, just like a .git folder
  class Archive < ApplicationRecord
    belongs_to :repository

    # TODO: Make name & owners updatable
    attr_accessor :name, :owner_account_email

    delegate :file_backups, to: :repository
    alias backups file_backups

    # Validations
    validates :repository_id, uniqueness: { message: 'already has an archive' }
    validates :remote_file_id, presence: true

    def default_api_connection
      api_connection_class.default
    end

    # Add the given email address as a viewer to the archive folder
    def grant_read_access_to(email)
      # TODO: Call method #share on remote_archive
      default_api_connection.share_file(remote_file_id, email, :reader)
    end

    # Remove the given email address as a viewer from the archive folder
    def remove_read_access_from(email)
      # TODO: Call method #unshare on remote_archive
      default_api_connection.unshare_file(remote_file_id, email)
    end

    # Set up the archive folder with the provider by creating it and granting
    # view access to the repository owner
    def setup
      raise 'Already set up' if setup_completed?

      create_external_folder
      # TODO: Move this to project and archive no longer needs to know the
      # =>    owner account
      grant_read_access_to(owner_account_email)
    end

    # Return true if setup has been completed (i.e. file resource is present)
    def setup_completed?
      remote_file_id.present?
    end

    private

    # Creates the archive folder with the provider
    def create_external_folder
      folder = sync_adapter_class.create(
        name: "#{name} (Archive)",
        parent_id: 'root',
        mime_type: mime_type_class.folder
      )
      self.remote_file_id = folder.id
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
