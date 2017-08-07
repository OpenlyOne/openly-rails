# frozen_string_literal: true

FactoryGirl.define do
  factory :project do
    title { Faker::HitchhikersGuideToTheGalaxy.starship.first(50).strip }
    owner { build(:user) }
  end
end
