# frozen_string_literal: true

FactoryGirl.define do
  factory :staged_file do
    project
    file_resource
    is_root false

    trait :root do
      is_root true
    end
  end
end
