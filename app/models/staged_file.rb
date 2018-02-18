# frozen_string_literal: true

# Handles associations between projects and file resources (staged files)
class StagedFile < ApplicationRecord
  # Associations
  belongs_to :project
  belongs_to :file_resource

  # Attributes
  attr_readonly :is_root

  # Callbacks
  # Prevent updates to staged files; these associations are immutable.
  before_update :raise_readonly_record

  # Prevent destruction of root folders; they cannot be destroyed
  before_destroy :raise_readonly_record, if: :root?

  # Validations
  validates :project_id,
            uniqueness: {
              scope: %i[file_resource_id],
              message: 'already has a staged file for this file resource'
            }
  validates :project_id,
            uniqueness: {
              scope: %i[is_root],
              message: 'already has a root file'
            },
            if: :is_root

  def root?
    is_root
  end

  private

  def raise_readonly_record
    raise ActiveRecord::ReadOnlyRecord
  end
end
