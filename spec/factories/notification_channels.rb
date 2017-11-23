# frozen_string_literal: true

FactoryGirl.define do
  factory :notification_channel do
    project
    association :file, factory: :file_items_base
    expires_at { Time.now + 1.day }
  end
end
