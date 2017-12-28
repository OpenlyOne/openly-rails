# frozen_string_literal: true

module VersionControl
  module FileCollections
    # A staged revision for a version controlled repository
    class Staged < FileCollection
      # Count files in working directory (includes root)
      def count
        lock do
          Dir["#{workdir}/**/*"].count
        end
      end

      # Create or update a file identified by its OID with the given attributes.
      # Return created/updated file.
      def create_or_update(attributes)
        lock do
          # Try to find existing file with ID and update it
          file = find_by_id(attributes[:id])
          return file.update(attributes) if file.present?

          # File does not yet exist, go ahead and create it
          VersionControl::Files::Staged.create(self, attributes)
        end
      end

      # Create the root folder with the given attributes and return it
      def create_root(attributes)
        lock do
          @root = VersionControl::Files::Staged::Root.create(self, attributes)
        end
      end

      # Return true if file with given ID exists in repository.
      # Return false otherwise.
      def exists?(id)
        lock do
          path_for_file(id)&.present?
        end
      rescue Errno::ENOENT
        false
      end

      # Find a file in the repository by its ID
      # Raises ActiveRecord::RecordNotFound error if file is not found
      def find(id)
        lock do
          file = find_by_id(id)
          return file if file.present?

          # File was not found, raise error!
          raise ActiveRecord::RecordNotFound,
                "Couldn't find file with id: #{id}"
        end
      end

      # Find a file by its id
      # Return nil if not found
      def find_by_id(id)
        lock do
          file_path = path_for_file(id)
          find_by_path(file_path)
        end

      # Return nil if file was not found
      rescue Errno::ENOENT, Errno::EINVAL
        nil
      end

      # Find a file by its path
      # Return nil if not found
      def find_by_path(path)
        lock do
          VersionControl::File.new(self, metadata_for(path))
        end

      # Return nil if file was not found
      rescue Errno::ENOENT, Errno::EINVAL
        nil
      end

      # Return the path for a given file identified by its OID.
      def path_for_file(id)
        # Raise error if id is not a String
        raise(Errno::EINVAL, 'ID must be a String.') unless id.is_a? String

        lock do
          # Find file and return its path
          path = Dir.glob("#{workdir}/**/#{id}").first
          return path if path.present?

          # No file found, raise error
          raise Errno::ENOENT, "File named #{id} does not exist in #{workdir}"
        end
      end

      # The root folder
      def root
        @root ||= lock { find_by_id(root_id) }
      end

      # The id for the root folder
      def root_id
        @root_id ||=
          lock do
            Dir.entries(workdir).find do |entry|
              !entry.start_with?('.')
            end
          end
      end

      private

      # Load the YAML metadata from the provided path
      def load_metadata(path)
        lock do
          YAML.load_file(metadata_path_from_file_path(path))&.symbolize_keys
        end
      end

      # Return the metadata for a file in this repository identified by its path
      def metadata_for(path)
        # Raise error if id is not a String
        raise(Errno::EINVAL, 'Path must be a String.') unless path.is_a? String

        lock do
          id = ::File.basename(path)
          load_metadata(path).merge(
            id: id,
            parent_id: parent_id_from_file_path(path),
            is_root: (id == root_id)
          )
        end
      end

      # Generate the metadata path based on the file path
      def metadata_path_from_file_path(path)
        lock do
          ::File.directory?(path) ? "#{path}/.self" : path
        end
      end

      # Return the file's parent ID from the file's path
      # Return nil if parent is the working directory
      def parent_id_from_file_path(path)
        # The path to the parent
        parent_path = Pathname.new(::File.expand_path('..', path))

        # The parent path relative to the repository's working directory
        relative_path = parent_path.relative_path_from(Pathname.new(workdir))

        # The parent id is the basename to string
        parent_id = relative_path.basename.to_s

        # Return nil if parent is the working directory
        parent_id == '.' ? nil : parent_id
      end
    end
  end
end
