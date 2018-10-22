# frozen_string_literal: true

FactoryBot.define do
  factory :profiles_base do
    transient do
      account_email nil
    end

    name      { Faker::Name.name }
    about     { Faker::Lorem.paragraph }
    account do
      build(:account, user: Profiles::User.new(name: name),
                      force_email: account_email)
    end
    handle    { Faker::Internet.user_name(name.first(26).strip, %w[_]) }
    location  { "#{city}, #{state}, USA" }

    trait :with_social_links do
      link_to_website   { Faker::Internet.url }
      link_to_facebook  { Faker::Internet.url('facebook.com') }
      link_to_twitter   { Faker::Internet.url('twitter.com') }
    end

    trait :with_random_color_scheme do
      color_scheme { Color.options.sample }
    end

    transient do
      city  { Faker::Address.city }
      state { Faker::Address.state }
    end
  end
end
