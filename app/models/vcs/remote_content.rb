# frozen_string_literal: true

module VCS
  # Mapping of remote file ID & content to local content
  # Allows multiple remote files to map to the same content version
  class RemoteContent < ApplicationRecord
    # Associations
    belongs_to :repository
    belongs_to :content

    # Validations
    validates :remote_file_id,
              presence: true,
              uniqueness: { scope: %i[repository_id remote_content_version_id] }
    validates :remote_content_version_id, presence: true
  end
end
