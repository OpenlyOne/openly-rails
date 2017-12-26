# frozen_string_literal: true

module VersionControl
  module Files
    class Staged < VersionControl::File
      # A repository's root folder, inherits from the Folder file type
      class Root < Folder
        # Root's parent is always nil
        def parent_id
          puts "Warning: #parent_id called for #{self.class}"
          nil
        end

        # Raise ActiveRecord::RecordInvalid if file is invalid for creation
        # File is valid for creation if no root folder exists yet
        def validate_for_creation!
          lock do
            return if @file_collection.root_id.nil?
            raise ActiveRecord::RecordInvalid
          end
        end

        private

        # Overwrite move_to method
        # Root is never moved or deleted
        def move_to(*args); end

        # The path of the root folder
        def path
          ::File.expand_path(id, @file_collection.workdir)
        end
      end
    end
  end
end
