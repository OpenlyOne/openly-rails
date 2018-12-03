# frozen_string_literal: true

module VCS
  # A repository-wide unique record for identifying files across branches and
  # versions
  class File < ApplicationRecord
    belongs_to :repository
    has_many :file_thumbnails, dependent: :destroy

    has_many :repository_branches, through: :repository, source: :branches

    has_many :versions, dependent: :destroy
    has_many :versions_of_children,
             class_name: 'VCS::Version',
             foreign_key: :parent_id,
             dependent: :destroy
  end
end
