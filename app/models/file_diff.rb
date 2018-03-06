# frozen_string_literal: true

# Class for handling diffing of File Resources
class FileDiff < ApplicationRecord
  include Diffing

  # Associations
  belongs_to :revision
  belongs_to :file_resource
  belongs_to :current_snapshot, class_name: 'FileResource::Snapshot',
                                optional: true
  belongs_to :previous_snapshot, class_name: 'FileResource::Snapshot',
                                 optional: true

  # Validations
  # Either current or previous snapshot must be present
  validates :current_snapshot_id, presence: true, unless: :previous_snapshot_id
  validates :previous_snapshot_id, presence: true, unless: :current_snapshot_id
end
