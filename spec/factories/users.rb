# frozen_string_literal: true

FactoryGirl.define do
  factory :user do
    name { Faker::Name.name }
    account { build(:account, user: User.new(name: name)) }
    handle { build(:handle, profile: User.new(name: name)) }
  end
end
