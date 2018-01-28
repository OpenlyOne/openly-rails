# frozen_string_literal: true

FactoryGirl.define do
  factory :project do
    title { Faker::HitchhikersGuideToTheGalaxy.starship.first(50).strip }
    description     { Faker::Lorem.paragraph }
    tags            { Faker::Lorem.words }
    sequence(:slug) { |n| "project-slug-#{n}" }
    owner           { build(:user) }
  end
end
