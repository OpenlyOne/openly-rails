# frozen_string_literal: true

RSpec.describe Contribution, type: :model do
  subject(:contribution) { build :contribution, project: project }

  let(:project) { create :project }

  describe '#setup', :vcr do
    subject(:setup) { contribution.setup(creator: current_account.user) }

    let(:contribution) { build :contribution, project: project, branch: nil }

    let(:api_connection) do
      Providers::GoogleDrive::ApiConnection.new(user_acct)
    end
    let(:user_acct)       { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }
    let(:tracking_acct)   { ENV['GOOGLE_DRIVE_TRACKING_ACCOUNT'] }

    # create test folder
    before { prepare_google_drive_test(api_connection) }

    # share test folder
    before do
      api_connection
        .share_file(google_drive_test_folder_id, tracking_acct, :writer)
    end

    # delete test folder
    after { tear_down_google_drive_test(api_connection) }

    let(:last_commit)     { project.revisions.last }
    let(:current_account) { create :account, email: user_acct }
    let(:project) do
      create :project, :with_repository, owner: current_account.user
    end
    let(:link_to_folder) do
      "https://drive.google.com/drive/folders/#{google_drive_test_folder_id}"
    end
    let(:set_up_project) do
      create :project_setup, link: link_to_folder, project: project
    end

    before do
      folder =
        create_folder(name: 'Folder', parent_id: google_drive_test_folder_id)
      create_file(name: 'File 1', parent: folder)
      create_file(name: 'File 2', parent: folder)

      set_up_project

      # and the project has one uncaptured file change
      create_file(name: 'File 3', parent_id: google_drive_test_folder_id)

      setup
    end

    it 'copies files from last commit' do
      expect(contribution.branch.files.without_root.count)
        .to eq last_commit.committed_files.count
      expect(
        contribution.branch
                    .files.without_root
                    .map(&:current_version_id)
      ).to match_array(
        last_commit.committed_files.map(&:version_id)
      )
    end

    it 'gives creator of contribution edit access to files' do
      expect(
        api_connection.find_file!(
          contribution.branch.root.remote_file_id,
          fields: 'capabilities'
        ).capabilities.can_edit
      ).to be true

      expect(
        api_connection.find_file!(
          contribution.branch.files.without_root.first.remote_file_id,
          fields: 'capabilities'
        ).capabilities.can_edit
      ).to be true
    end
  end

  # TODO: Extract into shared context because revision_restore_spec uses these
  # =>    exact methods
  def create_folder(name:, parent_id:)
    Providers::GoogleDrive::FileSync.create(
      name: name,
      parent_id: parent_id,
      mime_type: Providers::GoogleDrive::MimeType.folder,
      api_connection: api_connection
    )
  end

  def create_file(name:, parent: nil, parent_id: nil, content: nil)
    parent_id ||= parent&.id
    Providers::GoogleDrive::FileSync.create(
      name: name,
      parent_id: parent_id,
      mime_type: Providers::GoogleDrive::MimeType.document,
      api_connection: api_connection
    ).tap do |file|
      file.update_content(content) if content.present?
    end
  end
end
