# frozen_string_literal: true

FactoryGirl.define do
  factory :account do
    email { Faker::Internet.unique.email }
    password { Faker::Internet.password(8, 128) }
  end
end
