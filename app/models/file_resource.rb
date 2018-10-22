# frozen_string_literal: true

# FileResource represents a file on GoogleDrive, Dropbox, OneDrive, ...
class FileResource < ApplicationRecord
  include Resourceable
  include Snapshotable
  include Stageable
  include Syncable
  # must be last, so that backup is made after snapshot is persisted
  include Backupable

  self.inheritance_column = 'provider_id'

  # Associations
  belongs_to :parent, class_name: model_name, optional: true
  has_many :children, class_name: model_name, inverse_of: :parent,
                      foreign_key: :parent_id

  # Attributes
  attr_readonly :provider_id

  scope :order_by_name_with_folders_first, lambda { |table: nil|
    table ||= table_name
    folder_mime_type = Providers::GoogleDrive::MimeType.folder
    order(
      "#{table}.mime_type IN (#{connection.quote(folder_mime_type)}) desc, " \
      "#{table}.name asc"
    )
  }

  # Validations
  validates :provider_id, presence: true
  validates :external_id, presence: true
  validates :external_id, uniqueness: { scope: :provider_id },
                          if: :will_save_change_to_external_id?

  validate :cannot_be_its_own_parent, if: :parent_association_loaded?

  # Only perform validation if no errors have been encountered
  with_options unless: :any_errors? do
    validates_associated :parent, if: :parent_association_loaded?
    validate :cannot_be_its_own_ancestor, if: :will_save_change_to_parent_id?
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

  def folder?
    Object.const_get("#{provider}::MimeType").folder?(mime_type)
  end

  # Return all children that are folders
  def subfolders
    children.select(&:folder?)
  end

  # This method must be defined on subclasses
  def thumbnail_version_id
    raise(
      '#thumbnail_version_id must not be called from super class FileResource'
    )
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
end
