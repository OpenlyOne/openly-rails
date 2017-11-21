# frozen_string_literal: true

FactoryGirl.define do
  factory :file_items_folder,
          class: FileItems::Folder,
          parent: :file_items_base do
    transient do
      google_apps_type { 'folder' }
    end
  end
end
