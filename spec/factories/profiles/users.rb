# frozen_string_literal: true

FactoryGirl.define do
  factory :user, class: Profiles::User do
    name { Faker::Name.name }
    account { build(:account, user: Profiles::User.new(name: name)) }
    handle { Faker::Internet.user_name(name.first(26).strip, %w[_]) }
  end
end
