# frozen_string_literal: true

module VCS
  # The entry point for version control. It all starts with a repository.
  class Repository < ApplicationRecord
    has_many :branches, dependent: :destroy

    has_one :archive, dependent: :destroy
    has_many :files, dependent: :destroy
    has_many :file_snapshots, through: :files
    has_many :file_backups, through: :file_snapshots, source: :backup

    has_many :contents, dependent: :destroy
    has_many :remote_contents, dependent: :delete_all

    # TODO: Delete all associated records in this repository on destroy rather
    # =>    than deleting them 1 by 1
    # =>    Add #cleanup method that deletes orphaned records
  end
end
