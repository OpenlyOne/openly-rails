# frozen_string_literal: true

FactoryGirl.define do
  factory :vc_file_collection, class: VersionControl::FileCollection do
    skip_create

    transient do
      repository { build :vc_repository }
    end

    initialize_with { new(repository) }
  end
end
