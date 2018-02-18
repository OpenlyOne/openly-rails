# frozen_string_literal: true

# FileResource represents a file on GoogleDrive, Dropbox, OneDrive, ...
class FileResource < ApplicationRecord
  include Snapshotable
  include Stageable
  include Syncable

  self.inheritance_column = 'provider_id'

  # Associations
  belongs_to :parent, class_name: 'FileResource', optional: true

  # Attributes
  attr_readonly :provider_id

  # Validations
  validates :provider_id, presence: true
  validates :external_id, presence: true
  validates :external_id, uniqueness: { scope: :provider_id },
                          if: :external_id_changed?

  validate :cannot_be_its_own_parent, if: :parent_association_loaded?

  # Only perform validation if no errors have been encountered
  with_options unless: :any_errors? do
    validates_associated :parent, if: :parent_association_loaded?
    validate :cannot_be_its_own_ancestor, if: :parent_id_changed?
  end

  # Require presence of metadata unless file resource is deleted
  with_options unless: :deleted? do
    validates :name, presence: true
    validates :mime_type, presence: true
    validates :content_version, presence: true
  end

  # Typecasting providers
  class << self
    def find_sti_class(type_name)
      entities[type_name.to_i] || super
    end

    def sti_name
      entities.invert[self]
    end

    def entities
      providers.transform_values do |provider|
        "FileResources::#{provider}".constantize
      end
    end

    def providers
      Provider::PROVIDERS
    end
  end

  # Recursively collect parents
  def ancestors
    return [] if parent.nil?
    [parent] + parent.ancestors
  end

  # Recursively collect ids of parents
  def ancestors_ids
    ancestors.map(&:id)
  end

  def deleted?
    is_deleted
  end

  def provider
    "Providers::#{provider_name}".constantize
  end

  private

  def any_errors?
    errors.any?
  end

  def cannot_be_its_own_ancestor
    return unless ancestors_ids.include? id
    errors.add(:base, 'File resource cannot be its own ancestor')
  end

  def cannot_be_its_own_parent
    return unless self == parent
    errors.add(:base, 'File resource cannot be its own parent')
  end

  def parent_association_loaded?
    association(:parent).loaded?
  end

  def provider_name
    self.class.providers[provider_id]
  end
end
