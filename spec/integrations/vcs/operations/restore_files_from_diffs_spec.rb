# frozen_string_literal: true

RSpec.describe VCS::Operations::RestoreFilesFromDiffs, type: :model do
  subject(:restorer) do
    described_class.new(file_diffs: file_diffs, target_branch: branch)
  end

  let(:branch)        { create :vcs_branch }
  let(:file_diffs)    { [file1_diff, file2_diff, folder_diff] }
  let!(:file1_diff)   { create :vcs_file_diff, new_version: file1_v }
  let!(:file2_diff)   { create :vcs_file_diff, new_version: file2_v }
  let!(:folder_diff)  { create :vcs_file_diff, new_version: folder_v }

  let(:file1_v)       { create :vcs_version, parent_id: folder_v.file_id }
  let(:file2_v)       { create :vcs_version, parent_id: folder_v.file_id }
  let(:folder_v)      { create :vcs_version }

  describe '#restore', :delayed_job do
    before { restorer.restore }

    let(:file_restore_jobs) do
      Delayed::Job.where(queue: FileRestoreJob.queue_name)
    end

    let(:folder_restore_job) do
      file_restore_job_where(
        file_id: folder_diff.file_id,
        version_id: folder_diff.new_version_id
      )
    end
    let(:file1_restore_job) do
      file_restore_job_where(
        file_id: file1_diff.file_id,
        version_id: file1_diff.new_version_id
      )
    end
    let(:file2_restore_job) do
      file_restore_job_where(
        file_id: file2_diff.file_id,
        version_id: file2_diff.new_version_id
      )
    end

    it 'creates file restore jobs for each file diff' do
      expect(file_restore_jobs.count).to eq 3
      expect(folder_restore_job).to be_present
      expect(file1_restore_job).to be_present
      expect(file2_restore_job).to be_present
    end

    it 'creates file restore jobs in correct order' do
      expect(folder_restore_job.id).to be < file1_restore_job.id
      expect(folder_restore_job.id).to be < file2_restore_job.id
    end

    context 'when passing an active record relation' do
      let(:file_diffs) { VCS::FileDiff.all }

      it 'still works' do
        expect(file_restore_jobs.count).to eq 3
      end
    end
  end
end

def file_restore_job_where(file_id:, version_id:)
  file_restore_jobs
    .where("handler LIKE '%file_id: #{file_id}\n%'")
    .where("handler LIKE '%version_id: #{version_id}\n%'")
    .first
end
