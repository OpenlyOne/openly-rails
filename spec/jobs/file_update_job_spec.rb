# frozen_string_literal: true

RSpec.shared_examples 'adds file to repo X' do |repo_nr|
  it "adds file to repository #{repo_nr}" do
    expect { method }.to(
      change do
        send("repo#{repo_nr}").stage.files.exists?('file-id')
      end.from(false).to(true)
    )
  end
end

RSpec.shared_examples 'deletes file from repo X' do |repo_nr|
  it "deletes file from repository #{repo_nr}" do
    expect { method }.to(
      change do
        send("repo#{repo_nr}").stage.files.exists?('file-id')
      end.from(true).to(false)
    )
  end
end

RSpec.shared_examples 'ignores repo X' do |repo_nr|
  it "ignores repository #{repo_nr}" do
    repo = "repo#{repo_nr}"
    expect { method }.not_to(
      change do
        `du -s #{send(repo).workdir}`
      end
    )
  end
end

RSpec.shared_examples 'updates file in repo X' do |repo_nr|
  it "updates file in repository #{repo_nr}" do
    expect { method }.to(
      change do
        send("repo#{repo_nr}").stage.files.find('file-id').version
      end.to(1001)
    )
  end
end

RSpec.describe FileUpdateJob, type: :job do
  subject(:job) { FileUpdateJob.perform_later({}) }

  describe 'priority', delayed_job: true do
    it { expect(subject.priority).to eq 10 }
  end

  describe 'queue', delayed_job: true do
    it { expect(subject.queue_name).to eq 'file_update' }
  end

  describe '#perform' do
    before do
      mock_google_drive_requests if ENV['MOCK_GOOGLE_DRIVE_REQUESTS'] == 'true'
    end
    # mock job reschedulers to avoid infinite loops
    before do
      allow_any_instance_of(FileUpdateJob).to receive :check_for_changes_later
      allow_any_instance_of(FileUpdateJob).to receive :list_changes_on_next_page
    end
    subject(:method) { FileUpdateJob.perform_later(token: start_page_token) }
    let(:start_page_token) { 1 }
    let(:change_list) { GoogleDrive.list_changes(start_page_token, 5) }

    it 'calls #process_changes' do
      expect_any_instance_of(FileUpdateJob)
        .to receive(:process_changes)
        .with(instance_of(Google::Apis::DriveV3::ChangeList))
      subject
    end

    it 'lists changes on consecutive page' do
      expect_any_instance_of(FileUpdateJob)
        .to receive(:list_changes_on_next_page)
      subject
    end

    context 'when there is no next page' do
      let(:start_page_token) { 999_999_999 }

      it 'checks for changes later' do
        expect_any_instance_of(FileUpdateJob)
          .to receive(:check_for_changes_later)
        subject
      end
    end
  end

  describe '#check_for_changes_later' do
    before do
      mock_google_drive_requests if ENV['MOCK_GOOGLE_DRIVE_REQUESTS'] == 'true'
    end
    subject(:method)  { job.send :check_for_changes_later }
    let(:change_list) { GoogleDrive.list_changes(999_999_999) }
    let(:job)         { FileUpdateJob.new }

    it 'creates a FileUpdateJob to be run in 10s' do
      job.instance_variable_set :@change_list, change_list
      double = class_double('FileUpdateJob')
      expect(FileUpdateJob).to receive(:set)
        .with(wait: 10.seconds).and_return(double)
      expect(double).to receive(:perform_later)
        .with(token: change_list.new_start_page_token)
      subject
    end
  end

  describe '#list_changes_on_next_page' do
    before do
      mock_google_drive_requests if ENV['MOCK_GOOGLE_DRIVE_REQUESTS'] == 'true'
    end
    subject(:method)  { job.send :list_changes_on_next_page }
    let(:change_list) { GoogleDrive.list_changes(1, 5) }
    let(:job)         { FileUpdateJob.new }

    it 'creates a FileUpdateJob to be run immediately' do
      job.instance_variable_set :@change_list, change_list
      expect(FileUpdateJob).to receive(:perform_later)
        .with(token: change_list.next_page_token)
      subject
    end
  end

  describe '#process_changes(change_list)' do
    subject(:method)  { job.send :process_changes, change_list }
    let(:job)         { FileUpdateJob.new }
    let(:change_list) { Google::Apis::DriveV3::ChangeList.new }
    let(:changes)     { [change, change] }
    let(:change) do
      build :google_drive_change, :with_file,
            id: 'file-id',
            name: 'The Awesome File',
            parent: 'parent-id',
            mime_type: 'document',
            version: 1234,
            modified_time: Time.new(2007, 1, 1)
    end
    before  { change_list.changes = changes }
    after   { method }

    it 'calls #update_file_in_any_project for each entry in change list' do
      expect(job).to receive(:update_file_in_any_project)
        .twice
        .with(
          hash_including(
            id: 'file-id',
            parent_id: 'parent-id',
            name: 'The Awesome File',
            mime_type: 'document',
            version: 1234,
            modified_time: Time.new(2007, 1, 1)
          )
        )
    end

    context 'attribute hash passed to #update_file_in_any_project' do
      let(:changes) { [change] }

      context 'when removed is true' do
        before { change.removed = true }

        it 'passes parent_id = nil' do
          expect(job).to receive(:update_file_in_any_project)
            .with hash_including(parent_id: nil)
        end
      end

      context 'when file.trashed is true' do
        before { change.file.trashed = true }

        it 'passes parent_id = nil' do
          expect(job).to receive(:update_file_in_any_project)
            .with hash_including(parent_id: nil)
        end
      end
    end
  end

  describe '#update_file_in_any_project(new_attributes)' do
    subject(:method) { job.send :update_file_in_any_project, new_attributes }
    let(:job) { FileUpdateJob.new }

    let(:repo1) { create(:project).repository }
    let(:root1) { create :file, :root,  id: 'root-id', repository: repo1 }
    let(:file1) { create :file,         id: 'file-id', parent: root1 }

    let(:repo2) { create(:project).repository }
    let(:root2) { create :file, :root,  id: 'parent-id', repository: repo2 }
    let(:file2) { create :file,         id: 'some-id', parent: root2 }

    let(:repo3) { create(:project).repository }
    let(:root3) { create :file, :root,  id: 'parent-id', repository: repo3 }
    let(:file3) { create :file,         id: 'file-id', parent: root3 }

    let(:repo4) { create(:project).repository }
    let(:root4) { create :file, :root,  id: 'root-id', repository: repo4 }
    let(:file4) { create :file,         id: 'some-id', parent: root4 }

    # Initialize repos, roots, and files
    before { [file4, file3, file2, file1] }

    let(:new_attributes) do
      {
        id: 'file-id',
        name: 'New File Name',
        parent_id: 'parent-id',
        mime_type: 'document',
        version: 1001,
        modified_time: Time.zone.now
      }
    end

    it 'calls #lock for each repository' do
      expect(VersionControl::Repository).to receive(:lock).exactly(4).times
      method
    end

    it 'calls #create_or_update 3 times' do
      create_or_update_count = 0
      allow_any_instance_of(VersionControl::FileCollections::Staged)
        .to receive(:create_or_update) { |_| create_or_update_count += 1 }
      method
      expect(create_or_update_count).to eq 3
    end

    include_examples 'deletes file from repo X',  1
    include_examples 'adds file to repo X',       2
    include_examples 'updates file in repo X',    3
    include_examples 'ignores repo X',            4

    context 'when parent_id is nil' do
      before { new_attributes[:parent_id] = nil }

      include_examples 'deletes file from repo X',  1
      include_examples 'ignores repo X',            2
      include_examples 'deletes file from repo X',  3
      include_examples 'ignores repo X',            4
    end
  end
end
