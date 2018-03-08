# frozen_string_literal: true

FactoryGirl.define do
  factory :project do
    sequence(:title) do |n|
      "#{n} #{Faker::HitchhikersGuideToTheGalaxy.starship}".first(50).strip
    end
    description     { Faker::Lorem.paragraph }
    tags            { Faker::Lorem.words }
    sequence(:slug) { |n| "project-slug-#{n}" }
    owner           { build(:user) }
    is_public       { false }
  end
end
