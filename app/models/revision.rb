# frozen_string_literal: true

# Revisions represent a snapshot of a project with all its files
class Revision < ApplicationRecord
  # Associations
  belongs_to :project
  belongs_to :parent, class_name: 'Revision', optional: true, autosave: false
  belongs_to :author, class_name: 'Profiles::User'

  # attributes
  attr_readonly :project_id, :parent_id, :author_id

  # Validations
  # Require title and summary for published revisions
  with_options if: :published? do
    validates :title, presence: true
    validates :summary, presence: true
  end

  validate :parent_must_belong_to_same_project, if: :parent_id
  validate :can_only_have_one_revision_with_parent, if: :parent_id
  validate :can_only_have_one_origin_revision_per_project, unless: :parent_id

  def published?
    is_published
  end

  private

  def can_only_have_one_origin_revision_per_project
    return unless published_origin_revision_exists_for_project?
    errors.add(:base, 'An origin revision already exists for this project')
  end

  def can_only_have_one_revision_with_parent
    return unless published_revision_with_parent_exists?
    errors.add(:base,
               'Someone has committed changes to this project since you ' \
               'started reviewing changes. To prevent you and your team from' \
               "overwriting each other's changes, you cannot commit the " \
               'changes you are currently reviewing.')
  end

  def parent_must_belong_to_same_project
    return if parent.project_id == project_id
    errors.add(:parent, 'must belong to same project')
  end

  def published_origin_revision_exists_for_project?
    self.class.exists?(project_id: project_id, parent: nil, is_published: true)
  end

  def published_revision_with_parent_exists?
    self.class.exists?(parent_id: parent_id, is_published: true)
  end
end
