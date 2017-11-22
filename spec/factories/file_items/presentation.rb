# frozen_string_literal: true

FactoryGirl.define do
  factory :file_items_presentation,
          class: FileItems::Presentation,
          parent: :file_items_base do
    transient do
      google_apps_type { 'presentation' }
    end
  end
end
