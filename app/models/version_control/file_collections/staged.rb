# frozen_string_literal: true

module VersionControl
  module FileCollections
    # A collection of staged files for a version controlled repository
    class Staged < FileCollection
      delegate :lock, :workdir, to: :repository

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

      # Return true if file with given ID exists among files of revision
      # If an array is passed, will find and return a hash in the form of:
      # {'12345' => true, 'abcdef' => false, id => does_id_exist?}
      # Return false if file does not exist.
      def exists?(id_or_ids)
        lock do
          paths = find_paths_by_ids(Array.wrap(id_or_ids).compact).compact

          # If we are only looking for a single ID, return true or false now
          return paths.any? unless id_or_ids.is_a? Array

          # Transform paths into a hash in the form of 'id' => true/false
          id_or_ids.compact.map do |id|
            [id, paths.any? { |path| ::File.basename(path) == id }]
          end.to_h
        end
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
      # If an array is passed, will find and return all matching files
      # Return nil if not found
      def find_by_id(id_or_ids)
        lock do
          paths = find_paths_by_ids Array.wrap(id_or_ids)
          files = paths.map do |path|
            find_by_path(path)
          end

          # Return array if array was passed. Single instance, otherwise.
          id_or_ids.is_a?(Array) ? files : files.first
        end
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

      # Find paths for an array of ids by globbing the repository's workdir
      def find_paths_by_ids(ids)
        lock do
          # Escape the ids to find to prevent * or ? from being parsed as
          # glob meta-characters
          escaped_ids = ids.map { |id| Shellwords.escape(id) }
          paths = Dir.glob("#{workdir}/**/{#{escaped_ids.join(',')}}")

          # sort by ids
          ids.map do |id|
            paths.detect { |path| ::File.basename(path) == id }
          end
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
            # TODO: Use glob here -- it automatically filters out hidden files
            #       In essence: Dir.glob("#{workdir}/*")
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

      # TODO: Use relative paths
      # Return the metadata for a file in this repository identified by its path
      def metadata_for(path)
        # Raise error if id is not a String
        raise(Errno::EINVAL, 'Path must be a String.') unless path.is_a? String

        lock do
          id = ::File.basename(path)
          load_metadata(path).merge(
            id: id,
            parent_id: parent_id_from_absolute_file_path(path),
            is_root: (id == root_id)
            # TODO: Pass path variable
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
      # TODO: Use relative file paths and delete this method
      def parent_id_from_absolute_file_path(path)
        # The path relative to the repository's working directory
        relative_path =
          Pathname.new(path).relative_path_from(Pathname.new(workdir))

        self.class.parent_id_from_relative_path(relative_path)
      end
    end
  end
end
