# TODO: DELETE ME
# frozen_string_literal: true
#
# require 'integrations/shared_contexts/skip_project_archive_setup'
#
# RSpec.describe VCS::StagedFile, type: :model do
#   include_context 'skip project archive setup'
#
#   describe '.with_current_or_committed_snapshot' do
#     subject(:staged_files) do
#       described_class.with_current_or_committed_snapshot
#     end
#
#     let(:project) { create :project, :with_repository }
#     let(:repo)    { project.repository }
#     let(:branch)  { project.master_branch }
#     # file records
#     let!(:f1)     { create :vcs_file_record, repository: repo }
#     let!(:f2)     { create :vcs_file_record, repository: repo }
#     let!(:f3)     { create :vcs_file_record, repository: repo }
#     let!(:f4)     { create :vcs_file_record, repository: repo }
#     # have snapshots
#     let!(:f1s1)   { create :vcs_file_snapshot, file_record: f1 }
#     # snapshots fo file record 2
#     let!(:f2s1)   { create :vcs_file_snapshot, file_record: f2 }
#     let!(:f2s2)   { create :vcs_file_snapshot, file_record: f2 }
#     # file record 3
#     let!(:f3s1)   { create :vcs_file_snapshot, file_record: f3 }
#     # file record 4
#     let!(:f4s1)   { create :vcs_file_snapshot, file_record: f4 }
#
#     let(:commit1) { create :vcs_commit, branch: branch }
#     let(:commit2) { create :vcs_commit, branch: branch, parent: commit1 }
#
#     before do
#       commit1.committed_snapshots = [f1s1, f2s1]
#       commit1.update!(is_published: true)
#
#       commit2.committed_snapshots = [f2s2, f3s1]
#       commit2.update!(is_published: true)
#
#       create(:vcs_staged_file, :deleted, branch: branch, file_record: f1)
#       create(:vcs_staged_file, branch: branch, file_record: f2)
#       create(:vcs_staged_file, :deleted, branch: branch, file_record: f3)
#       create(:vcs_staged_file, branch: branch, file_record: f4)
#     end
#
#     it 'returns staged files that have a current or committed snapshot' do
#       expect(staged_files.map(&:file_record)).to contain_exactly(f2, f3, f4)
#     end
#
#     it 'returns the correct snapshots' do
#       expect(staged_files.map(&:committed_snapshot_id))
#         .to contain_exactly(f2s2.id, f3s1.id, nil)
#     end
#   end
# end
