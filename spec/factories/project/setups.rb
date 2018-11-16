# frozen_string_literal: true

FactoryBot.define do
  factory :project_setup, class: 'Project::Setup' do
    association :project, :skip_archive_setup
    is_completed { false }
    link { '' }

    trait :with_link do
      link { file.external_link }

      transient do
        file { create :vcs_staged_file, :folder }
      end
    end

    trait :completed do
      is_completed { true }

      # Skip validations, otherwise it will throw an error because of link being
      # nil
      skip_validation
    end

    trait :skip_validation do
      to_create { |instance| instance.save(validate: false) }
    end
  end
end
