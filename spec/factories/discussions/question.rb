# frozen_string_literal: true

FactoryGirl.define do
  factory :discussions_question,
          class: Discussions::Question,
          parent: :discussions_base do
  end
end
