# frozen_string_literal: true

FactoryGirl.define do
  factory :file_diff do
    revision
    file_resource
    current_snapshot { file_resource.current_snapshot }
    first_three_ancestors { Faker::Lorem.words(3) }

    trait :with_previous_snapshot do
      association :previous_snapshot, factory: :file_resource_snapshot
    end
  end
end
