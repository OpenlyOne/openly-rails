# frozen_string_literal: true

FactoryBot.define do
  factory :user, aliases: %i[author],
                 class: Profiles::User, parent: :profiles_base do
  end
end
