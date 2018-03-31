# frozen_string_literal: true

FactoryBot.define do
  factory :profiles_base do
    name    { Faker::Name.name }
    about   { Faker::Lorem.paragraph }
    account { build(:account, user: Profiles::User.new(name: name)) }
    handle  { Faker::Internet.user_name(name.first(26).strip, %w[_]) }
  end
end
