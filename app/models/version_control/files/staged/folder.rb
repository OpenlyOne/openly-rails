# frozen_string_literal: true

module VersionControl
  module Files
    class Staged < VersionControl::File
      # A folder type file
      class Folder < Staged
        # The files contained within this folder
        def children
          # If file has no path, there are no children
          return [] unless path.present?

          # Return children, initialize if necessary
          @children ||=
            lock do
              # List all files in folder's directory
              Dir.glob("#{path}/*").map do |child|
                # Initialize each file/child
                child_id = ::File.basename(child)
                file_collection.find(child_id)
              end
            end
        end

        private

        # Write the folder to the repository
        def create
          lock do
            # Create directory
            Dir.mkdir(path)

            # Write metadata
            write_metadata
          end
        end

        # The path to the folder's metadata file
        def metadata_path
          return nil unless path.present?
          "#{path}/.self"
        end
      end
    end
  end
end
