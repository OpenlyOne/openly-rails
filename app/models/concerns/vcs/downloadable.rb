# frozen_string_literal: true

module VCS
  # A backupable staged file
  module Downloadable
    extend ActiveSupport::Concern

    included do
      # Callbacks
      after_save :download_content, if: :download_on_save?

      # Delegations
      delegate :content, to: :current_snapshot, allow_nil: true
      delegate :text_type?, to: :mime_type_instance
      delegate :downloaded?, to: :content, prefix: true
    end

    # Should this file be downloaded on save?
    # Yes, if text type and backed up and not yet downloaded
    def download_on_save?
      text_type? && backed_up? && !content_downloaded?
    end

    # Perform the downloading of content and save to plain_text column of
    # snapshot's content
    def download_content
      downloader =
        VCS::Operations::ContentDownloader
        .new(remote_file_id: backup.external_id)
      content.update!(plain_text: downloader.plain_text)
      downloader.done
    end

    private

    def mime_type_instance
      Providers::GoogleDrive::MimeType.new(mime_type)
    end
  end
end
