# frozen_string_literal: true

RSpec.describe Project, type: :model do
  subject(:project)         { create :project }
  let(:skip_archive_setup)  { true }

  before do
    next unless skip_archive_setup

    allow_any_instance_of(VCS::Archive).to receive(:setup)
  end

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
      create :vcs_version, thumbnail: VCS::FileThumbnail.first,
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
      expect { project.destroy }.to change(VCS::FileThumbnail, :count).to(0)
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

  describe 'scope: :where_setup_is_complete' do
    subject(:method)             { Project.where_setup_is_complete }
    let!(:with_complete_setup)   { create_list :project, 2 }
    let!(:with_incomplete_setup) { create_list :project, 2 }
    let!(:with_no_setup)         { create_list :project, 2 }

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
    let(:project)     { create :project }

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
end
