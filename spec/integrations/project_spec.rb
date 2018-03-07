# frozen_string_literal: true

RSpec.describe Project, type: :model do
  subject(:project) { create :project }

  describe 'deleteable' do
    before do
      # add collaborators
      project.collaborators = create_list :user, 2

      # add root folder
      project.root_folder = create :file_resource

      # add staged files
      project.file_resources_in_stage = create_list :file_resource, 2

      # add drafted revisions with committed files and file diffs
      revisions = create_list :revision, 2, project: project
      revisions.each do |revision|
        revision.committed_files = create_list :committed_file, 2
        revision.file_diffs = create_list :file_diff, 2
      end

      # add published revisions
      revision1 = create :revision, project: project
      revision2 = create :revision, project: project, parent: revision1
      [revision1, revision2].each do |revision|
        revision.committed_files = create_list :committed_file, 2
        revision.file_diffs = create_list :file_diff, 2
      end
      revision1.update!(is_published: true, title: 'origin')
      revision2.update!(is_published: true, title: 'second revision')
    end

    it { expect { project.destroy }.not_to raise_error }
  end

  describe 'non_root_file_resources_in_stage#with_current_snapshot' do
    subject(:method) do
      project.non_root_file_resources_in_stage.with_current_snapshot
    end
    let(:file_resources_with_current_snapshot) { create_list :file_resource, 5 }
    let(:file_resources_without_current_snapshot) do
      create_list :file_resource, 5, :deleted
    end

    before do
      project.file_resources_in_stage << (
        file_resources_with_current_snapshot +
        file_resources_without_current_snapshot
      )
    end

    it 'returns file resources where current_snapshot is present' do
      expect(method.map(&:id))
        .to contain_exactly(*file_resources_with_current_snapshot.map(&:id))
    end

    it 'does not return file resources where current_snapshot = nil' do
      intersection_of_ids =
        method.map(&:id) & file_resources_without_current_snapshot.map(&:id)
      expect(intersection_of_ids).not_to be_any
    end
  end

  describe 'scope: :where_profile_is_owner_or_collaborator(profile)' do
    subject(:method) { Project.where_profile_is_owner_or_collaborator(profile) }
    let(:profile)         { create :user }
    let!(:owned_projects) { create_list :project, 3, owner: profile }
    let!(:collaborations) { create_list :project, 3 }
    let!(:other_projects) { create_list :project, 3 }

    before do
      # add profile as a collaborator
      collaborations.each do |project|
        project.collaborators << profile
      end
    end

    it 'returns projects owned by profile' do
      expect(method.map(&:id)).to include(*owned_projects.map(&:id))
    end

    it 'returns projects in which profile is a collaborator' do
      expect(method.map(&:id)).to include(*collaborations.map(&:id))
    end

    it 'does not return other projects' do
      expect(method.map(&:id)).not_to include(*other_projects.map(&:id))
    end

    context 'when owned project has collaborators' do
      let(:collaborators) { create_list :user, 3 }

      before do
        owned_projects.each do |project|
          project.collaborators << collaborators
        end
      end

      it 'returns only distinct projects' do
        expect(method.map(&:id).uniq).to eq method.map(&:id)
      end
    end
  end

  describe 'validations when import_google_drive_folder_on_save = true', :vcr do
    before  { prepare_google_drive_test(api_connection) }
    after   { tear_down_google_drive_test(api_connection) }

    subject                 { create(:project) }
    let(:mime_type)         { folder_type }
    let(:folder_type)       { Providers::GoogleDrive::MimeType.folder }
    let(:document_type)     { Providers::GoogleDrive::MimeType.document }
    let(:user_acct)         { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }
    let(:tracking_acct)     { ENV['GOOGLE_DRIVE_TRACKING_ACCOUNT'] }
    let(:api_connection) do
      Providers::GoogleDrive::ApiConnection.new(user_acct)
    end
    let(:share_folder) do
      api_connection
        .share_file(google_drive_test_folder_id, tracking_acct)
    end
    let(:link) do
      Providers::GoogleDrive::Link.for(external_id: @created_file.id,
                                       mime_type: folder_type)
    end

    # share test folder
    before { share_folder }

    # Create folder
    before do
      @created_file = Providers::GoogleDrive::FileSync.create(
        name: 'Test File',
        parent_id: google_drive_test_folder_id,
        mime_type: mime_type,
        api_connection: api_connection
      )
    end

    before { project.import_google_drive_folder_on_save = true }
    before { project.link_to_google_drive_folder = link }
    before { project.valid? }

    context 'when link to google drive folder is valid' do
      it 'does not add an error' do
        expect(project.errors[:link_to_google_drive_folder].size)
          .to eq 0
      end
    end

    context 'when link to google drive folder is invalid' do
      let(:link) { 'https://invalid-folder-link' }

      it 'adds an error' do
        expect(project.errors[:link_to_google_drive_folder])
          .to include 'appears not to be a valid Google Drive link'
      end
    end

    context 'when link to google drive folder is inaccessible' do
      let(:share_folder) { nil }

      it 'adds an error' do
        expect(project.errors[:link_to_google_drive_folder])
          .to include 'appears to be inaccessible. Have you shared the '\
                      'resource with '\
                      "#{Settings.google_drive_tracking_account}?"
      end
    end

    context 'when link to google drive folder is not a folder' do
      let(:mime_type) { document_type }

      it 'adds an error' do
        expect(project.errors[:link_to_google_drive_folder])
          .to include 'appears not to be a Google Drive folder'
      end
    end
  end
end
