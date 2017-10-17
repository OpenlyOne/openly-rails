# frozen_string_literal: true

FactoryGirl.define do
  factory :vc_repository, class: VersionControl::Repository do
    skip_create

    transient do
      sequence(:name) { |n| Faker::File.file_name('', "repo-#{n}", 'git', '') }
      dir             { Rails.root.join('spec', 'tmp').to_s }
      path            { "#{dir}/#{name}" }
      bare            { :bare }
    end

    initialize_with do
      VersionControl::Repository.create path, bare
    end
  end
end
