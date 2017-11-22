# frozen_string_literal: true

FactoryGirl.define do
  factory :file_items_spreadsheet,
          class: FileItems::Spreadsheet,
          parent: :file_items_base do
    transient do
      google_apps_type { 'spreadsheet' }
    end
  end
end
