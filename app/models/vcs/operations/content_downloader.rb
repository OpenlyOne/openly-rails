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
        @plain_text ||=
          Henkei::Server.extract_text(downloaded_file.tap(&:rewind)).strip
      end

      # Close the tempfile
      def done
        tempfile_for_download.close!
      end

      private

      def remote_file
        @remote_file ||= Providers::GoogleDrive::FileSync.new(remote_file_id)
      end

      # Return downloaded file. If not yet downloaded, download.
      def downloaded_file
        return @downloaded_file if @downloaded_file.present?

        download_remote_file
        @downloaded_file = tempfile_for_download
      end

      def download_remote_file
        remote_file.download(destination: tempfile_for_download)
      end

      # TODO: Move tempfile handling to FileSync#download method and have
      # =>    tempfile be returned from #download method rather than being
      # =>    required as an argument
      def tempfile_for_download
        @tempfile_for_download ||= Tempfile.new.tap(&:binmode)
      end
    end
  end
end
