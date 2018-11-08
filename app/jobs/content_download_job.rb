# frozen_string_literal: true

# Download content
class ContentDownloadJob < ApplicationJob
  queue_as :content_download
  queue_with_priority 50

  def perform(*args)
    variables_from_arguments(*args)

    content.update!(plain_text: downloader.plain_text)
    downloader.done
  end

  private

  attr_accessor :remote_file_id, :content

  def downloader
    @downloader ||=
      VCS::Operations::ContentDownloader.new(remote_file_id: remote_file_id)
  end

  # Set instance variables from the job's arguments
  def variables_from_arguments(*args)
    self.remote_file_id = args[0][:remote_file_id]
    self.content        = VCS::Content.find(args[0][:content_id])
  end
end
