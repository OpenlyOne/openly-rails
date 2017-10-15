# frozen_string_literal: true

FactoryGirl.define do
  factory :discussions_base do
    title { Faker::Hipster.sentence.first(100) }
    association :initiator, factory: :user
    initial_reply { build(:reply, discussion: Discussions::Suggestion.new) }
    project

    after(:stub) { |discussion| discussion.scoped_id = 1 }
  end
end
