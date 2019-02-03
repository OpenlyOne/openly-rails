# frozen_string_literal: true

FactoryBot.define do
  factory :contribution do
    project
    association :creator, factory: :user
    association :branch, factory: :vcs_branch
    title       { Faker::HarryPotter.quote }
    description { Faker::Lorem.paragraph }

    trait :mock_setup do
      branch do
        project.repository.branches.create!.tap do |fork|
          create :vcs_file_in_branch, :root,
                 file: project.master_branch.root.file, branch: fork
          fork.copy_committed_files_from(project.master_branch)

          fork.files.without_root.each do |file|
            remote_file_id = Faker::Crypto.unique.sha1
            content_version = '1'

            # Map new combination of remote file ID and content version to
            # existing content ID
            file.committed_version.content.remote_contents.create!(
              repository: file.repository,
              remote_file_id: remote_file_id,
              remote_content_version_id: content_version
            )

            file.update!(
              current_version_id: file.committed_version,
              remote_file_id: remote_file_id,
              content_version: content_version,
              parent: file.committed_version.parent,
              name: file.committed_version.name,
              mime_type: file.committed_version.mime_type,
              is_deleted: false
            )
          end
        end
      end
    end

    trait :setup do
      branch { nil }

      to_create(&:setup)
    end
  end
end
