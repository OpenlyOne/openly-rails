# frozen_string_literal: true

FactoryGirl.define do
  factory :discussions_base do
    title { Faker::Hipster.sentence.first(100) }
    association :initiator, factory: :user
    project
  end
end
