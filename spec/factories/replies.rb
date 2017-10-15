# frozen_string_literal: true

FactoryGirl.define do
  factory :reply do
    content { Faker::Lorem.paragraphs.join("\n\n") }
    association :author, factory: :user
    discussion { build :discussions_suggestion, initial_reply: Reply.new }
  end
end
