# frozen_string_literal: true

# A syncable FileResource
module Stageable
  extend ActiveSupport::Concern

  included do
    has_many :stagings, class_name: 'StagedFile',
                        dependent: :restrict_with_exception
    has_many :staging_projects, class_name: 'Project',
                                through: :stagings,
                                source: :project

    # Associations with staged files that are not root
    # This association is used in #restage to restage file resource only for
    # non root stagings.
    has_many :non_root_stagings,
             -> { where is_root: false },
             class_name: 'StagedFile',
             dependent: false
    has_many :non_root_staging_projects, class_name: 'Project',
                                         through: :non_root_stagings,
                                         source: :project

    # Restage the stageable if parent changed
    after_save :restage, if: :saved_change_to_parent_id?
  end

  private

  # Stage the file resource in all projects where parent is staged
  def restage
    self.non_root_staging_project_ids = parent&.staging_project_ids
  end
end
