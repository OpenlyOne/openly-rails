# frozen_string_literal: true

module VCS
  # The archive for storing file backups, just like a .git folder
  class Archive < ApplicationRecord
    include VCS::HavingRemote

    belongs_to :repository

    # TODO: Make name & owners updatable
    attr_accessor :name, :owner_account_email

    delegate :file_backups, to: :repository
    alias backups file_backups
    delegate :grant_read_access_to, :revoke_access_from, to: :remote

    # Validations
    validates :repository_id, uniqueness: { message: 'already has an archive' }
    validates :remote_file_id, presence: true

    def default_api_connection
      api_connection_class.default
    end

    # Makes the archive publicly accessible
    def grant_public_access
      # TODO: Call method #share on remote_archive
      default_api_connection.share_file_with_anyone(remote_file_id, :reader)
    end

    # Removes public access to the archive
    def remove_public_access
      # TODO: Call method #unshare on remote_archive
      default_api_connection.unshare_file_with_anyone(remote_file_id)
    end

    # Set up the archive folder with the provider by creating it and granting
    # view access to the repository owner
    def setup
      raise 'Already set up' if setup_completed?

      create_remote_folder
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
    def create_remote_folder
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
