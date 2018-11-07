# frozen_string_literal: true

module VCS
  # The content of a file (equivalent of a blob in Git)
  class Content < ApplicationRecord
    # Associations
    belongs_to :repository
    has_many :remote_contents, dependent: :delete_all
  end
end
