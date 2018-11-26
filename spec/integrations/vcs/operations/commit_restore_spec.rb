# frozen_string_literal: true

RSpec.describe VCS::Operations::CommitRestore, type: :model do
  subject(:restorer) do
    described_class.new(commit: commit, target_branch: branch, author: author)
  end

  let(:commit)  { branch.commits.create_draft_and_commit_files!(author) }
  let(:branch)  { create :vcs_branch }
  let(:author)  { create :user }

  let!(:root)   { create :vcs_file_in_branch, :root, branch: branch }
  let!(:folder) { create :vcs_file_in_branch, :folder, parent_in_branch: root }
  let!(:file1)  { create :vcs_file_in_branch, parent_in_branch: folder }
  let!(:file2)  { create :vcs_file_in_branch, parent_in_branch: folder }
  let!(:file3)  { create :vcs_file_in_branch, parent_in_branch: root }
  let(:file4)   { create :vcs_file_in_branch, parent_in_branch: root }

  before do
    commit

    file1.update(parent_in_branch: root)
    file2.update(parent_in_branch: root)
    folder.tap(&:mark_as_removed).save
    file4
  end

  describe '#restore', :delayed_job do
    before { restorer.restore }

    let(:file_restore_jobs) do
      Delayed::Job.where(queue: FileRestoreJob.queue_name)
    end

    let(:folder_restore_job) do
      file_restore_job_where(
        file_id: folder.file_id,
        version_id: folder.file.versions.first.id
      )
    end
    let(:file1_restore_job) do
      file_restore_job_where(
        file_id: file1.file_id,
        version_id: file1.file.versions.first.id
      )
    end
    let(:file2_restore_job) do
      file_restore_job_where(
        file_id: file2.file_id,
        version_id: file2.file.versions.first.id
      )
    end
    let(:file4_restore_job) do
      file_restore_job_where(
        file_id: file4.file_id,
        version_id: nil
      )
    end

    it 'creates file restore jobs for each changed file' do
      expect(file_restore_jobs.count).to eq 4
      expect(folder_restore_job).to be_present
      expect(file1_restore_job).to be_present
      expect(file2_restore_job).to be_present
      expect(file4_restore_job).to be_present
    end

    it 'creates file restore jobs in correct order' do
      expect(folder_restore_job.id).to be < file1_restore_job.id
      expect(folder_restore_job.id).to be < file2_restore_job.id
    end
  end
end

def file_restore_job_where(file_id:, version_id:)
  file_restore_jobs
    .where("handler LIKE '%file_id: #{file_id}\n%'")
    .where("handler LIKE '%version_id: #{version_id}\n%'")
    .first
end
