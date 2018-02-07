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
  subject(:job)     { FileUpdateJob.new }
  let(:change_list) { instance_double Google::Apis::DriveV3::ChangeList }
  let(:token)       { 'token' }

  # prevent recursive jobs
  before { allow(FileUpdateJob).to receive(:perform_later) }

  before do
    allow(GoogleDrive)
      .to receive(:list_changes).with(token).and_return change_list
  end

  describe 'priority' do
    it { expect(subject.priority).to eq 10 }
  end

  describe 'queue' do
    it { expect(subject.queue_name).to eq 'file_update' }
  end

  describe '#perform' do
    subject(:perform) { job.perform(token: 'token') }

    before do
      allow(job).to receive(:process_changes)
      allow(job).to receive(:create_new_file_update_job)
    end

    it 'calls #list_changes on GoogleDrive with token' do
      expect(GoogleDrive).to receive(:list_changes).with('token')
      perform
    end

    it 'calls #process_changes with change list returned by Google Drive' do
      expect(job).to receive(:process_changes).with(change_list)
      perform
    end

    it 'calls #create_new_file_update_job' do
      expect(job).to receive(:create_new_file_update_job)
      perform
    end
  end

  describe '#check_for_changes_later(new_start_page_token)' do
    subject(:method)  { job.send :check_for_changes_later, 'token' }
    let(:new_job)     { class_double FileUpdateJob }

    it 'creates a FileUpdateJob to be run in 10s' do
      expect(FileUpdateJob)
        .to receive(:set).with(wait: 10.seconds).and_return new_job
      expect(new_job).to receive(:perform_later).with(token: 'token')
      method
    end
  end

  describe '#create_new_file_update_job(change_list)' do
    subject(:method) { job.send :create_new_file_update_job, change_list }

    before do
      allow(change_list).to receive(:next_page_token).and_return next_page_token
      allow(change_list).to receive(:new_start_page_token).and_return 'token'
    end

    after { method }

    context 'when next_page_token is present' do
      let(:next_page_token) { 'next' }

      it { expect(job).to receive(:list_changes_on_next_page).with('next') }
    end

    context 'when next_page_token is not present' do
      let(:next_page_token) { nil }

      it { expect(job).to receive(:check_for_changes_later).with('token') }
    end
  end

  describe '#list_changes_on_next_page(new_page_token)' do
    subject(:method) { job.send :list_changes_on_next_page, 'token' }

    it 'creates a FileUpdateJob to be run immediately' do
      expect(FileUpdateJob).to receive(:perform_later).with(token: 'token')
      method
    end
  end

  describe '#process_changes(change_list)' do
    subject(:process_changes) { job.send :process_changes, change_list }
    let(:changes)             { %w[change change] }

    before do
      allow(change_list).to receive(:changes).and_return changes
      allow(GoogleDrive).to receive(:attributes_from_change_record)
        .with('change').and_return 'attributes'
    end

    after { process_changes }

    it 'calls #update_file_in_any_project for each entry in change list' do
      expect(job)
        .to receive(:update_file_in_any_project).twice.with('attributes')
    end
  end

  describe '#update_file_in_any_project(new_attributes)' do
    subject(:method) { job.send :update_file_in_any_project, new_attributes }

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
