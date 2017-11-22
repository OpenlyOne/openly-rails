# frozen_string_literal: true

FactoryGirl.define do
  factory :file_items_drawing,
          class: FileItems::Drawing,
          parent: :file_items_base do
    transient do
      google_apps_type { 'drawing' }
    end
  end
end
