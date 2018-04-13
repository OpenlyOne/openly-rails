# frozen_string_literal: true

FactoryBot.define do
  factory :profiles_base do
    name      { Faker::Name.name }
    about     { Faker::Lorem.paragraph }
    account   { build(:account, user: Profiles::User.new(name: name)) }
    handle    { Faker::Internet.user_name(name.first(26).strip, %w[_]) }
    location  { "#{city}, #{state}, USA" }

    trait :with_social_links do
      link_to_website   { Faker::Internet.url }
      link_to_facebook  { Faker::Internet.url('facebook.com') }
      link_to_twitter   { Faker::Internet.url('twitter.com') }
    end

    transient do
      city  { Faker::Address.city }
      state { Faker::Address.state }
    end
  end
end
