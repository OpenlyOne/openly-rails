# frozen_string_literal: true

FactoryGirl.define do
  factory :file_items_form,
          class: FileItems::Form,
          parent: :file_items_base do
    transient do
      google_apps_type { 'form' }
    end
  end
end
