# frozen_string_literal: true

module VCS
  # The entry point for version control. It all starts with a repository.
  class Repository < ApplicationRecord
    has_many :branches, dependent: :destroy

    has_one :archive, dependent: :destroy
    has_many :files, dependent: :destroy do
      def root
        joins(:staged_instances)
          .find_by("#{VCS::FileInBranch.table_name}": { is_root: true })
      end
    end
    has_many :file_versions, class_name: 'VCS::Version',
                             through: :files,
                             source: :versions
    has_many :file_backups, through: :file_versions, source: :backup

    has_many :contents, dependent: :destroy
    has_many :remote_contents, dependent: :delete_all

    # TODO: Delete all associated records in this repository on destroy rather
    # =>    than deleting them 1 by 1
    # =>    Add #cleanup method that deletes orphaned records
  end
end
