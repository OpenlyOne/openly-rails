# frozen_string_literal: true

FactoryGirl.define do
  factory :revision do
    author
    project
    title         { Faker::HarryPotter.quote }
    summary       { Faker::Lorem.paragraph }
    is_published  false

    trait :published do
      is_published true
    end

    trait :with_parent do
      parent { create(:revision, project: project) }
    end

    after(:build) do |revision|
      next if revision.parent&.project.nil?
      revision.project = revision.parent.project
    end
  end
end
