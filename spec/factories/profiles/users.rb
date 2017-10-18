# frozen_string_literal: true

FactoryGirl.define do
  factory :user, class: Profiles::User do
    name { Faker::Name.name }
    account { build(:account, user: Profiles::User.new(name: name)) }
    handle { build(:handle, profile: Profiles::User.new(name: name)) }
  end
end
