# frozen_string_literal: true

RSpec.describe Contribution, type: :model do
  subject(:contribution) { build :contribution, project: project }

  let(:project) { create :project }

  describe '#accept(revision:)' do
    subject(:accept) { contribution.accept(revision: revision) }

    let(:contribution) { create :contribution, :mock_setup, project: project }
    let(:creator)      { contribution.creator }
    let(:revision) do
      contribution.prepare_revision_for_acceptance(author: create(:user))
    end
    let(:project) { create :project, :skip_archive_setup, :with_repository }
    let!(:root)   { create :vcs_file_in_branch, :root, branch: master_branch }
    let(:master_branch) { project.master_branch }

    before { allow(master_branch).to receive(:restore_commit) }

    it 'publishes the revision on the master branch' do
      accept
      expect(project.revisions.last).to have_attributes(
        title: contribution.title,
        summary: contribution.description,
        author: contribution.creator
      )
    end

    it 'applies suggested changes to the master branch' do
      accept
      expect(master_branch)
        .to have_received(:restore_commit)
        .with(revision, author: creator)
    end

    it 'marks the contribution as accepted' do
      accept
      expect(contribution).to be_accepted
    end
  end

  describe '#prepare_revision_for_acceptance(author:)' do
    subject(:prepare_revision) do
      contribution.prepare_revision_for_acceptance(author: user)
    end

    let(:contribution)  { create :contribution }
    let(:project)       { contribution.project }
    let(:user)          { create :user }
    let!(:last_revision) do
      create :vcs_commit, :published, branch: project.master_branch
    end

    it 'creates a revision draft' do
      prepare_revision
      expect(contribution.revision).to have_attributes(
        is_published: false,
        parent: last_revision,
        title: contribution.title,
        summary: contribution.description,
        author: user
      )
    end
  end

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

    it 'creates contribution in project archive' do
      expect(contribution.branch.root.remote.parent_id)
        .to eq project.repository.archive.remote_file_id
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
