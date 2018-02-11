# frozen_string_literal: true

# FileResource represents a file on GoogleDrive, Dropbox, OneDrive, ...
class FileResource < ApplicationRecord
  self.inheritance_column = 'provider_id'

  # Attributes
  attr_readonly :provider_id

  # Validations
  validates :provider_id, presence: true
  validates :external_id, presence: true
  validates :external_id, uniqueness: { scope: :provider_id },
                          if: :external_id_changed?

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

  def deleted?
    is_deleted
  end

  def provider
    "Providers::#{provider_name}".constantize
  end

  private

  def provider_name
    self.class.providers[provider_id]
  end
end
