# frozen_string_literal: true

FactoryGirl.define do
  factory :file_items_file,
          class: FileItems::File,
          parent: :file_items_base do
    transient do
      google_apps_type { %w[document spreadsheet].sample }
    end
  end
end
