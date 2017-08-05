# frozen_string_literal: true

FactoryGirl.define do
  factory :handle do
    after(:build) do |handle|
      handle.profile = build(:user, handle: handle) unless handle.profile
      handle.identifier = Faker::Internet.user_name(handle.profile.name, %w[_])
    end
  end
end
