# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    transient do
      force_email { nil }
    end

    user { build(:user, account: Account.new) }
    email { force_email || Faker::Internet.unique.email(user.name) }
    password { Faker::Internet.password(8, 128) }
    admin { false }

    trait :admin do
      admin { true }
    end
  end
end
