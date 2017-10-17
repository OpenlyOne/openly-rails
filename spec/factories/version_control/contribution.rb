# frozen_string_literal: true

FactoryGirl.define do
  factory :vc_contribution, class: VersionControl::Contribution do
    skip_create

    transient do
      file { create :vc_file }
    end

    initialize_with do
      new(file&.send(:last_commit))
    end
  end
end
