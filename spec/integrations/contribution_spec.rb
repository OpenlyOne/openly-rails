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

    before do
      allow(VCS::Operations::RestoreFilesFromDiffs).to receive(:restore)
    end

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
      expect(VCS::Operations::RestoreFilesFromDiffs)
        .to have_received(:restore)
        .with(file_diffs: revision.file_diffs.includes(:version),
              target_branch: master_branch)
    end

    it 'marks the contribution as accepted' do
      accept
      expect(contribution).to be_accepted
    end

    context 'when new files are added in the contribution' do
      let!(:new_files) { create_list :vcs_committed_file, 3, commit: revision }

      before { revision.reload && revision.committed_files.reload }

      it 'copies the files over to master branch and marks them committed' do
        accept
        expect(master_branch.reload.files.without_root.count).to eq 3
        expect(master_branch.files.without_root.map(&:committed_version_id))
          .to match_array(new_files.map(&:version_id))
      end
    end
  end

  describe '#prepare_revision_for_acceptance(author:)' do
    subject(:prepare_revision) do
      contribution.prepare_revision_for_acceptance(author: user)
    end

    let(:contribution) do
      create :contribution, :mock_setup,
             origin_revision: origin_revision, project: project
    end
    let(:project) { create(:project, :skip_archive_setup, :with_repository) }
    let(:master_branch) { project.master_branch }
    let(:user)          { create :user }
    let(:origin_revision) do
      create :vcs_commit, :commit_files, branch: master_branch
    end

    let!(:root) { create :vcs_file_in_branch, :root, branch: master_branch }
    let!(:file_to_change_in_contribution_only) do
      create :vcs_file_in_branch, parent_in_branch: root
    end
    let!(:file_to_change_in_both) do
      create :vcs_file_in_branch, parent_in_branch: root
    end
    let!(:file_to_change_in_master_only) do
      create :vcs_file_in_branch, parent_in_branch: root
    end
    let!(:folder) do
      create :vcs_file_in_branch, :folder, parent_in_branch: root
    end

    before do
      origin_revision
      contribution

      # when changes are made on master
      file_to_change_in_both.update!(name: 'in both (new)')
      file_to_change_in_master_only.update!(name: 'master only (new)')
      # and committed
      create :vcs_commit, :commit_files, parent: origin_revision,
                                         branch: master_branch

      # when changes are made in the contribution
      contribution.files.find_by!(
        file_id: file_to_change_in_contribution_only.file_id
      ).update!(name: 'contrib only (new)')
      contribution.files.find_by!(
        file_id: file_to_change_in_both.file_id
      ).update!(parent: folder.file)

      prepare_revision
    end

    it 'creates a revision draft' do
      expect(contribution.revision).to have_attributes(
        is_published: false,
        parent: project.revisions.last,
        title: contribution.title,
        summary: contribution.description,
        author: user
      )
    end

    it 'calculates diffs relative to origin revision' do
      expect(contribution.revision.file_diffs.count).to eq 2
      expect(contribution.revision.file_diffs.count(&:rename?)).to eq 2
      expect(contribution.revision.file_diffs.count(&:movement?)).to eq 1
    end
  end

  describe '#setup', :vcr do
    subject(:setup) { contribution.setup(creator: current_account.user) }

    let(:contribution) do
      build :contribution, project: project, branch: nil,
                           origin_revision: origin_revision
    end

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

    let(:origin_revision) { project.revisions.last }
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

    it 'copies files from origin revision' do
      expect(contribution.branch.files.without_root.count)
        .to eq origin_revision.committed_files.count
      expect(
        contribution.branch
                    .files.without_root
                    .map(&:current_version_id)
      ).to match_array(
        origin_revision.committed_files.map(&:version_id)
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

  describe '#suggested_file_diffs' do
    subject(:file_diffs) { contribution.suggested_file_diffs }

    let(:contribution)  { create :contribution, :mock_setup, project: project }
    let(:project)     { create :project, :skip_archive_setup, :with_repository }
    let(:author)      { project.owner }
    let(:master)      { project.master_branch }
    let!(:root)       { create :vcs_file_in_branch, :root, branch: master }
    let!(:prior_files) do
      create_list :vcs_file_in_branch, 5, parent_in_branch: root
    end
    let!(:origin_revision) do
      master.commits.create_draft_and_commit_files!(author)
            .tap { |commit| commit.update!(is_published: true, title: 'c') }
    end

    let!(:deletion) { contribution.branch.files.without_root.second.destroy }
    let!(:addition) { create :vcs_file_in_branch, branch: contribution.branch }
    let!(:modification) do
      contribution.branch.files.without_root.second.tap do |file|
        file.update(name: 'new file name')
      end
    end

    it 'returns diffs of files changed in revision' do
      expect(file_diffs.map { |d| [d.file_id, d.new_version_id] })
        .to contain_exactly(
          [deletion.file_id, nil],
          [addition.file_id, addition.current_version_id],
          [modification.file_id, modification.current_version_id]
        )
    end

    it 'returns diffs relative to origin revision' do
      expect(file_diffs.map(&:commit).map(&:parent_id).uniq)
        .to contain_exactly(origin_revision.id)
    end

    it 'does not return diffs of files changed in master' do
      addition_in_master = create :vcs_file_in_branch, parent_in_branch: root
      expect(file_diffs.map(&:file_id))
        .not_to include(addition_in_master.file_id)
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
