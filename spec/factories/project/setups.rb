# frozen_string_literal: true

FactoryGirl.define do
  factory :project_setup, class: 'Project::Setup' do
    project
    is_completed false
    link { '' }

    trait :with_link do
      link { file_resource.external_link }

      transient do
        file_resource { create :file_resource, :folder }
      end
    end

    trait :completed do
      is_completed true

      # Skip validations, otherwise it will throw an error because of link being
      # nil
      skip_validation
    end

    trait :skip_validation do
      to_create { |instance| instance.save(validate: false) }
    end
  end
end
