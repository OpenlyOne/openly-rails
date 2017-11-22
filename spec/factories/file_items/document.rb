# frozen_string_literal: true

FactoryGirl.define do
  factory :file_items_document,
          class: FileItems::Document,
          parent: :file_items_base do
    transient do
      google_apps_type { 'document' }
    end
  end
end
