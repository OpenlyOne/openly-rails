# frozen_string_literal: true

RSpec.describe FileUpdateJob, type: :job do
  subject(:job) { FileUpdateJob.new }

  it { expect(subject.priority).to eq 10 }
  it { expect(subject.queue_name).to eq 'file_update' }

  describe '#perform' do
    subject(:perform) { job.perform(token: 'token') }

    before do
      api_connection = instance_double Providers::GoogleDrive::ApiConnection
      allow(Providers::GoogleDrive::ApiConnection)
        .to receive(:default).and_return api_connection
      allow(api_connection)
        .to receive(:list_changes).with('token').and_return 'change-list'
      allow(job).to receive(:process_changes)
      allow(job).to receive(:create_new_file_update_job)
    end

    it 'calls #process_changes' do
      expect(job).to receive(:process_changes).with('change-list')
      perform
    end

    it 'creates a new file update job' do
      expect(job).to receive(:create_new_file_update_job).with('change-list')
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
    let(:change_list) { instance_double Google::Apis::DriveV3::ChangeList }

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
    let(:change_list) { instance_double Google::Apis::DriveV3::ChangeList }

    before do
      allow(change_list).to receive(:changes).and_return %w[c1 c2]
      allow(job).to receive(:process_change)
    end

    it 'calls #process_change with each change' do
      process_changes
      expect(job).to have_received(:process_change).with('c1')
      expect(job).to have_received(:process_change).with('c2')
    end
  end

  describe '#process_change(change)' do
    subject(:process_change) { job.send :process_change, change }
    let(:change)    { instance_double Google::Apis::DriveV3::Change }
    let(:file)      { instance_double Google::Apis::DriveV3::File }
    let(:parents)   { %w[p1 p2 p3] }
    let(:branches)  { instance_double ActiveRecord::Relation }
    let(:branch1)   { instance_double VCS::Branch }
    let(:branch2)   { instance_double VCS::Branch }
    let(:file1)     { instance_double VCS::FileInBranch }
    let(:file2)     { instance_double VCS::FileInBranch }

    before do
      allow(change).to receive(:file_id).and_return 'id'
      allow(change).to receive(:file).and_return file
      allow(file).to receive(:parents).and_return parents if file.present?

      allow(VCS::Branch)
        .to receive(:where_files_include_remote_file_id)
        .and_return branches

      allow(branches)
        .to receive(:find_each)
        .and_yield(branch1)
        .and_yield(branch2)

      allow(VCS::FileInBranch)
        .to receive(:find_or_initialize_by)
        .with(remote_file_id: 'id', branch: branch1)
        .and_return file1
      allow(VCS::FileInBranch)
        .to receive(:find_or_initialize_by)
        .with(remote_file_id: 'id', branch: branch2)
        .and_return file2

      allow(file1).to receive(:pull)
      allow(file2).to receive(:pull)
    end

    it 'finds branches with the correct files' do
      process_change
      expect(VCS::Branch)
        .to have_received(:where_files_include_remote_file_id)
        .with(%w[id p1 p2 p3])
    end

    it 'calls #pull on each file' do
      process_change
      expect(file1).to have_received(:pull)
      expect(file2).to have_received(:pull)
    end

    context 'when file is not present' do
      let(:file) { nil }

      it 'find branches with files with remote id of change' do
        process_change
        expect(VCS::Branch)
          .to have_received(:where_files_include_remote_file_id)
          .with(['id'])
      end
    end

    context 'when files are not found in any branches' do
      before do
        allow(branches).to receive(:find_each).and_return []
      end

      it 'does not pull any file' do
        process_change
        expect(file1).not_to have_received(:pull)
        expect(file2).not_to have_received(:pull)
      end
    end
  end
end
