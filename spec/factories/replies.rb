# frozen_string_literal: true

FactoryGirl.define do
  factory :reply do
    content { Faker::Lorem.paragraphs.join("\n\n") }
    association :author, factory: :user
    association :discussion, factory: :discussions_suggestion
  end
end
