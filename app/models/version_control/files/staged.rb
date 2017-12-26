# frozen_string_literal: true

module VersionControl
  module Files
    # A staged revision for a version controlled repository
    class Staged < VersionControl::File
      # Cast StagedFile to correct type
      def self.new(file_collection, params)
        return super unless self == VersionControl::Files::Staged

        if params.delete(:is_root)
          Root.new(file_collection, params.except(:parent_id))
        elsif directory_type?(params[:mime_type])
          Folder.new(file_collection, params)
        else
          super
        end
      end

      # Create a new staged file
      def self.create(file_collection, params)
        file_collection.lock do
          file = new(file_collection, params)
          file.send :validate_for_creation!
          file.send :create
          file
        end
      end

      # Update the file with the provided params
      def update(params)
        # Exit if existing version is more recent than intended update
        return false unless params[:version] > version

        lock do
          # Move the file to a new location, if necessary
          move_to params[:parent_id]

          # Update file attributes
          @name           = params[:name]
          @mime_type      = params[:mime_type]
          @version        = params[:version]
          @modified_time  = params[:modified_time]

          # Persist new attributes to repository
          write_metadata if path.present?
        end

        # Return true if update has succeeded
        true
      end

      private

      # Create the file by writing its metadata to the repository
      def create
        lock do
          write_metadata
        end
      end

      # Return the file's metadata
      def metadata
        {
          name: name,
          mime_type: mime_type,
          version: version,
          modified_time: modified_time
        }
      end

      # The path to the file's metadata
      def metadata_path
        path
      end

      # Move the file to a new location specified by new_parent_id
      # If new_parent_id is nil, does not exist, or is outside of the
      # repository, the file is destroyed.
      def move_to(new_parent_id)
        # Exit if existing parent id is equal to the new parent id
        return if parent_id == new_parent_id

        # Commence the move
        lock do
          old_path    = path
          @path       = nil
          @parent_id  = new_parent_id

          # Complete the move and exit if path is present
          return ::File.rename(old_path, path) if path.present?

          # Path was not present, that means the file is meant to be deleted or
          # moved to a parent outside of this repository.
          # In either case, we want to destroy the file.
          FileUtils.remove_dir(old_path)
        end
      end

      # Return the path for the file in the repository's working directory
      def path
        @path ||=
          lock do
            ::File.expand_path(
              id,
              @file_collection.path_for_file(parent_id)
            )
          end
      rescue Errno::ENOENT, Errno::EINVAL
        @path = nil
      end

      # Raise ActiveRecord::RecordInvalid if file is invalid for creation
      # File is valid for creation if
      # a) path is set
      # b) file ID is unique
      def validate_for_creation!
        lock do
          return if path.present? && !file_collection.exists?(id)
          raise ActiveRecord::RecordInvalid
        end
      end

      # Write file metadata to repository
      def write_metadata
        lock do
          ::File.write(
            metadata_path,
            metadata.to_yaml
          )
        end
      end
    end
  end
end
