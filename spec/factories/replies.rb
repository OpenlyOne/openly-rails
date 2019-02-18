# frozen_string_literal: true

FactoryBot.define do
  factory :reply do
    author
    contribution
    content { Faker::Lorem.paragraph }
  end
end
