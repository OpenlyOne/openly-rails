# frozen_string_literal: true

RSpec.describe Project, type: :model do
  subject(:project) { create :project, :skip_archive_setup }

  describe 'deleteable', :delayed_job do
    before do
      master_branch = project.master_branch

      # add collaborators
      project.collaborators = create_list :user, 2

      # add setup
      root = create :vcs_file_in_branch, :root, branch: master_branch
      allow_any_instance_of(Project::Setup).to receive(:file).and_return(root)
      create :project_setup, :with_link, project: project

      # add files to branch
      create_list :vcs_file_in_branch, 2, :with_thumbnail, :with_backup,
                  branch: master_branch

      # Reuse the thumbnail for another version
      create :vcs_version, thumbnail: VCS::Thumbnail.first,
                           file: VCS::File.first

      # add drafted revisions with committed files and file diffs
      revisions = create_list :vcs_commit, 2, branch: master_branch
      revisions.each do |revision|
        revision.committed_files = create_list :vcs_committed_file, 2
        revision.file_diffs = create_list :vcs_file_diff, 2
      end

      # add published revisions
      revision1 = create :vcs_commit, branch: master_branch
      revision2 = create :vcs_commit, branch: master_branch, parent: revision1
      [revision1, revision2].each do |revision|
        revision.committed_files = create_list :vcs_committed_file, 2
        revision.file_diffs = create_list :vcs_file_diff, 2
      end
      revision1.update!(is_published: true, title: 'origin')
      revision2.update!(is_published: true, title: 'second revision')

      project.reload
    end

    it { expect { project.destroy }.not_to raise_error }
    it { expect { project.destroy }.to change(Delayed::Job, :count).to(0) }
    it 'destroys associated file thumbnails' do
      expect { project.destroy }.to change(VCS::Thumbnail, :count).to(0)
    end
  end

  describe 'scope: :with_permission_level(profile)' do
    subject(:method)  { Project.with_permission_level(profile) }
    let(:profile)     { creator }
    let(:creator)     { create :user }

    let!(:public_owned_projects) do
      create_list :project, 2, :public, :skip_archive_setup, owner: creator
    end
    let!(:public_collab_projects) do
      create_list(:project, 2, :public, :skip_archive_setup).tap do |projects|
        projects.each { |project| project.collaborators << creator }
      end
    end
    let!(:public_projects) do
      create_list :project, 2, :public, :skip_archive_setup
    end
    let!(:private_owned_projects) do
      create_list :project, 2, :private, :skip_archive_setup, owner: creator
    end
    let!(:private_collab_projects) do
      create_list(:project, 2, :private, :skip_archive_setup).tap do |projects|
        projects.each { |project| project.collaborators << creator }
      end
    end
    let!(:private_projects) do
      create_list :project, 2, :private, :skip_archive_setup
    end

    it 'sets collab permission on all owned & collaborator projects' do
      expect(method.select(&:can_collaborate?)).to match_array(
        public_owned_projects + public_collab_projects +
        private_owned_projects + private_collab_projects
      )
    end

    it 'sets view permission on all owned & collaborator & public projects' do
      expect(method.select(&:can_view?)).to match_array(
        public_owned_projects + public_collab_projects + public_projects +
        private_owned_projects + private_collab_projects
      )
    end

    it 'sets none permission on private projects' do
      expect(method.reject(&:can_view?)).to match_array(private_projects)
    end

    context 'when projects have collaborators' do
      let(:collaborators) { create_list :user, 3 }

      before do
        public_projects.each do |project|
          project.collaborators << collaborators
        end
      end

      it 'returns only distinct projects' do
        expect(method.map(&:id).uniq).to eq method.map(&:id)
      end
    end

    context 'when profile is nil' do
      let(:profile) { nil }

      it 'sets view permission on public projects' do
        expect(method.select(&:can_view?)).to match_array(
          public_owned_projects + public_collab_projects + public_projects
        )
      end

      it 'sets none permission on private projects' do
        expect(method.reject(&:can_view?)).to match_array(
          private_owned_projects + private_collab_projects + private_projects
        )
      end
    end
  end

  describe 'scope: :where_profile_is_owner_or_collaborator(profile)' do
    subject(:method) { Project.where_profile_is_owner_or_collaborator(profile) }
    let(:profile)         { create :user }
    let!(:owned_projects) do
      create_list :project, 3, :skip_archive_setup, owner: profile
    end
    let!(:collaborations) { create_list :project, 3, :skip_archive_setup }
    let!(:other_projects) { create_list :project, 3, :skip_archive_setup }

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

  describe 'scope: :where_setup_is_complete' do
    subject(:method)            { Project.where_setup_is_complete }
    let!(:with_complete_setup)  { create_list :project, 2, :skip_archive_setup }
    let!(:with_incomplete_setup) do
      create_list :project, 2, :skip_archive_setup
    end
    let!(:with_no_setup) { create_list :project, 2, :skip_archive_setup }

    before do
      with_complete_setup.each do |project|
        create :project_setup, :completed, project: project
      end
      with_incomplete_setup.each do |project|
        create :project_setup,
               :skip_validation, project: project, is_completed: false
      end
    end

    it 'returns projects with complete setup' do
      expect(method.map(&:id)).to match_array with_complete_setup.map(&:id)
    end
  end

  describe 'scope: :find_by_handle_and_slug!(handle, slug)' do
    subject(:method)  { Project.find_by_handle_and_slug!(handle, slug) }
    let(:handle)      { project.owner.handle }
    let(:slug)        { project.slug }
    let(:project)     { create :project, :skip_archive_setup }

    it { is_expected.to eq project }

    context 'when handle does not exist' do
      let(:handle) { 'does-not-exist' }
      it { expect { method }.to raise_error ActiveRecord::RecordNotFound }
    end

    context 'when slug does not exist' do
      let(:slug) { 'does-not-exist' }
      it { expect { method }.to raise_error ActiveRecord::RecordNotFound }
    end
  end

  describe '.create with is_public: true', :vcr do
    let(:project) do
      create :project, :public, owner_account_email: owner_email_address
    end
    let(:archive) { project.archive }

    let(:guest_api_connection) do
      Providers::GoogleDrive::ApiConnection.new(guest_email_address)
    end
    let(:owner_email_address) { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }
    let(:guest_email_address) { ENV['GOOGLE_DRIVE_COLLABORATOR_ACCOUNT'] }

    before do
      refresh_google_drive_authorization
      refresh_google_drive_authorization(guest_api_connection)
    end

    it 'shares view access to the archive with anyone (e.g. guest)' do
      remote_archive =
        Providers::GoogleDrive::FileSync.new(
          archive.remote_file_id,
          api_connection: guest_api_connection
        )

      expect(remote_archive.name).to be_present
    end
  end

  describe '#update', :vcr do
    context 'when private project is made public' do
      let(:project) do
        create :project, owner_account_email: owner_email_address
      end
      let(:archive) { project.archive }

      let(:guest_api_connection) do
        Providers::GoogleDrive::ApiConnection.new(guest_email_address)
      end
      let(:owner_email_address) { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }
      let(:guest_email_address) { ENV['GOOGLE_DRIVE_COLLABORATOR_ACCOUNT'] }

      before do
        refresh_google_drive_authorization
        refresh_google_drive_authorization(guest_api_connection)

        project.update!(is_public: true)
      end

      it 'grants view access to the archive to anyone (e.g. guest)' do
        remote_archive =
          Providers::GoogleDrive::FileSync.new(
            archive.remote_file_id,
            api_connection: guest_api_connection
          )

        expect(remote_archive.name).to be_present
      end
    end

    context 'when public project is made private' do
      let(:project) do
        create :project, :public, owner_account_email: owner_email_address
      end
      let(:archive) { project.archive }
      let(:remote_archive_id) { archive.remote_file_id }

      let(:owner_api_connection) { api_connection.new(owner_email_address) }
      let(:owner_email_address) { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }

      let(:guest_api_connection) { api_connection.new(guest_email_address) }
      let(:guest_email_address) { ENV['GOOGLE_DRIVE_COLLABORATOR_ACCOUNT'] }

      let(:api_connection) { Providers::GoogleDrive::ApiConnection }

      before do
        refresh_google_drive_authorization
        refresh_google_drive_authorization(owner_api_connection)
        refresh_google_drive_authorization(guest_api_connection)
        project.update!(is_public: false)
      end

      it 'continues to be accessible to the owner' do
        remote_archive =
          Providers::GoogleDrive::FileSync.new(
            archive.remote_file_id,
            api_connection: owner_api_connection
          )

        expect(remote_archive.name).to be_present
      end

      it 'removes view access to the archive from non-collaborators' do
        expect { guest_api_connection.find_file!(remote_archive_id) }
          .to raise_error(
            Google::Apis::ClientError,
            "notFound: File not found: #{remote_archive_id}."
          )
      end
    end
  end

  describe '#touch_captured_at' do
    subject(:touch) { project.touch_captured_at }

    it 'sets captured_at to now' do
      touch
      project.reload
      expect(project.captured_at.utc).to be_within(1.second).of Time.zone.now
    end

    it 'does not change updated_at' do
      expect { touch }.to change(project, :updated_at)
    end
  end
end
