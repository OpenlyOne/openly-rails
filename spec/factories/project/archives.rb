# frozen_string_literal: true

FactoryBot.define do
  factory :project_archive, class: 'Project::Archive' do
    association :project, :skip_archive_setup
    file_resource
  end
end
