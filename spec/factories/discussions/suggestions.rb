# frozen_string_literal: true

FactoryGirl.define do
  factory :discussions_suggestion,
          class: Discussions::Suggestion,
          parent: :discussions_base do
  end
end
