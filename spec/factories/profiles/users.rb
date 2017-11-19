# frozen_string_literal: true

FactoryGirl.define do
  factory :user,
          class: Profiles::User,
          parent: :profiles_base do
  end
end
