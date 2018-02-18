# frozen_string_literal: true

module Providers
  module GoogleDrive
    # Wrapper class for Google::Apis::DriveV3::File
    class File < Google::Apis::DriveV3::File
      # Return true if the file has been removed or trashed
      def self.deleted?(file)
        file.nil? || (file.trashed == true)
      end
    end
  end
end
