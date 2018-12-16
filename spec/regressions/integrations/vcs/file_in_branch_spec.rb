# frozen_string_literal: true

RSpec.describe VCS::FileInBranch, type: :model, vcr: true do
  before { prepare_google_drive_test }
  after  { tear_down_google_drive_test }

  subject(:file_in_branch) do
    create :vcs_file_in_branch, branch: branch, remote_file_id: remote_file.id
  end

  let(:branch) { create :vcs_branch }

  let!(:remote_file) do
    Providers::GoogleDrive::FileSync.create(
      name: 'Test Folder',
      parent_id: google_drive_test_folder_id,
      mime_type: Providers::GoogleDrive::MimeType.folder
    )
  end

  describe '#pull_children' do
    subject(:pull_children) { file_in_branch.pull_children }

    let!(:remote_subfile1) do
      Providers::GoogleDrive::FileSync.create(
        name: 'Remote Subfile 1',
        parent_id: remote_file.id,
        mime_type: Providers::GoogleDrive::MimeType.document
      )
    end
    let!(:remote_subfile2) do
      Providers::GoogleDrive::FileSync.create(
        name: 'Remote Subfile 2',
        parent_id: remote_file.id,
        mime_type: Providers::GoogleDrive::MimeType.document
      )
    end

    let!(:subfile1_in_branch) do
      create :vcs_file_in_branch,
             branch: branch, remote_file_id: remote_subfile1.id
    end
    let!(:subfile2_in_branch) do
      create :vcs_file_in_branch,
             branch: branch, remote_file_id: remote_subfile2.id
    end

    it 'updates subfile1 and subfile2 parent' do
      expect(file_in_branch.children_in_branch.count).to eq 0
      pull_children
      expect(file_in_branch.children_in_branch.reload.count).to eq 2
    end

    it 'does NOT updates subfile1 and subfile2 name' do
      pull_children
      expect(file_in_branch.children_in_branch.map(&:name))
        .not_to contain_exactly(remote_subfile1.name, remote_subfile2.name)
    end

    context 'when some children are new' do
      before { subfile1_in_branch.destroy && subfile2_in_branch.destroy }

      it 'creates and pulls subfile1 and subfile2' do
        pull_children
        expect(file_in_branch.children_in_branch.count).to eq 2
        expect(file_in_branch.children_in_branch.map(&:name))
          .to contain_exactly(remote_subfile1.name, remote_subfile2.name)
      end
    end

    context 'when some children have been deleted' do
      before do
        [subfile1_in_branch, subfile2_in_branch].each do |subfile_in_branch|
          subfile_in_branch.mark_as_removed
          subfile_in_branch.save!
        end
      end

      it 'creates and pulls subfile1 and subfile2' do
        pull_children
        expect(file_in_branch.children_in_branch.count).to eq 2
        expect(file_in_branch.children_in_branch.map(&:name))
          .to contain_exactly(remote_subfile1.name, remote_subfile2.name)
      end
    end
  end
end
