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
    let(:change1)     { instance_double Google::Apis::DriveV3::Change }
    let(:change2)     { instance_double Google::Apis::DriveV3::Change }
    let(:file1)       { instance_double FileResources::GoogleDrive }
    let(:file2)       { instance_double FileResources::GoogleDrive }

    before do
      allow(change_list).to receive(:changes).and_return [change1, change2]
      allow(change1).to receive(:file_id).and_return 'file1'
      allow(change2).to receive(:file_id).and_return 'file2'

      allow(FileResources::GoogleDrive)
        .to receive(:find_or_initialize_by)
        .with(external_id: 'file1')
        .and_return file1
      allow(FileResources::GoogleDrive)
        .to receive(:find_or_initialize_by)
        .with(external_id: 'file2')
        .and_return file2
    end

    after { process_changes }

    it 'calls #pull on each file' do
      expect(file1).to receive(:pull)
      expect(file2).to receive(:pull)
    end
  end
end
