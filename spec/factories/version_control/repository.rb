# frozen_string_literal: true

FactoryGirl.define do
  factory :repository, class: VersionControl::Repository do
    skip_create

    transient do
      sequence(:name) { |n| "repo-#{n}" }
      dir             { Rails.root.join(Settings.file_storage).to_s }
      path            { "#{dir}/#{name}" }
      bare            { nil }
    end

    trait :bare do
      bare { :bare }
    end

    initialize_with do
      VersionControl::Repository.create path, bare
    end
  end
end
