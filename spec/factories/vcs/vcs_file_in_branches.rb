# frozen_string_literal: true

FactoryBot.define do
  factory :vcs_file_in_branch, class: 'VCS::FileInBranch' do
    transient do
      parent_in_branch { nil }
      repository do
        parent_in_branch&.branch&.repository ||
          branch&.repository ||
          create(:vcs_repository)
      end
      # Allows overriding the mime type used for the versions
      # Needed for the deleted trait because mime_type is nil
      version_mime_type { mime_type || 'application/vnd.google-apps.document' }
      # Allows overriding the remote file ID used for the remote content
      # Needed for the files without remote ID, otherwise fails
      content_remote_file_id { remote_file_id || Faker::Crypto.unique.sha1 }
    end

    with_parent

    branch          { parent_in_branch&.branch || create(:vcs_branch) }
    file            { create(:vcs_file, repository: repository) }
    remote_file_id  { Faker::Crypto.unique.sha1 }
    name            { Faker::File.file_name('', nil, nil, '') }
    content_version { rand(1..1000) }
    mime_type       { 'application/vnd.google-apps.document' }
    is_root         { false }

    trait :folder do
      mime_type { 'application/vnd.google-apps.folder' }
    end

    trait :with_parent do
      parent { parent_in_branch&.file || create(:vcs_file) }
    end

    trait :root do
      is_root { true }
      folder
      parent_id { nil }
    end

    trait :with_thumbnail do
      thumbnail { create :vcs_file_thumbnail, file_id: file_id }
    end

    trait :deleted do
      name { nil }
      content_version { nil }
      mime_type { nil }
      is_deleted { true }
    end

    trait :with_versions do
      with_current_version
      with_committed_version
    end

    trait :with_current_version do
      with_parent

      transient do
        remote_content do
          create :vcs_remote_content,
                 remote_content_version_id: content_version,
                 repository: repository,
                 remote_file_id: content_remote_file_id
        end
      end

      current_version do
        create(:vcs_version,
               file: file, name: name, parent: parent,
               mime_type: version_mime_type, content: remote_content.content)
      end
    end

    trait :with_committed_version do
      committed_version do
        create(:vcs_version, file: file, mime_type: version_mime_type)
      end
    end

    trait :unchanged do
      with_current_version
      committed_version { current_version }
    end

    trait :changed do
      with_versions
    end

    trait :with_backup do
      after(:create) do |file_in_branch|
        create(:vcs_file_backup, file_version: file_in_branch.current_version)
        file_in_branch.current_version.reload_backup
      end
    end
  end
end
