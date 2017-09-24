# frozen_string_literal: true

FactoryGirl.define do
  factory :discussions_issue,
          class: Discussions::Issue,
          parent: :discussions_base do
  end
end
