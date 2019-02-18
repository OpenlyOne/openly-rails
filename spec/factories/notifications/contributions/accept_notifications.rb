# frozen_string_literal: true

FactoryBot.define do
  factory :contributions_accept_notification, parent: :notification do
    association :notifiable, factory: :contribution
    key { 'contribution.accept' }
  end
end
