# frozen_string_literal: true

module VCS
  module Operations
    # Download content from remote file
    class ContentDownloader
      # Attributes
      attr_accessor :remote_file_id

      def initialize(remote_file_id:)
        self.remote_file_id = remote_file_id
      end

      # Return the plain text version of the downloaded file
      def plain_text
        @plain_text ||= Henkei::Server.extract_text(downloaded_file).strip
      end

      # Close the tempfile
      def done
        downloaded_file.close!
      end

      private

      def remote_file
        @remote_file ||= Providers::GoogleDrive::FileSync.new(remote_file_id)
      end

      # Return downloaded file. If not yet downloaded, download.
      def downloaded_file
        @downloaded_file ||= remote_file.download
      end
    end
  end
end
