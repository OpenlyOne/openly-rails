# frozen_string_literal: true

FactoryBot.define do
  factory :project_archive, class: 'Project::Archive' do
    transient do
      project_owner_account_email nil
    end

    project do
      build(:project,
            :skip_archive_setup,
            owner_account_email: project_owner_account_email)
    end
    file_resource
  end
end
