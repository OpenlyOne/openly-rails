# frozen_string_literal: true

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
      allow_any_instance_of(FileUpdateJob).to receive(:check_for_changes_later)
      allow_any_instance_of(FileUpdateJob)
        .to receive(:list_changes_on_next_page)
    end
    # set page_size to 5 for list_changes
    before do
      if ENV['MOCK_GOOGLE_DRIVE_REQUESTS'] != 'true'
        allow(GoogleDrive).to(
          receive(:list_changes)
            .and_wrap_original { |m, token| m.call(token, 5) }
        )
      end
    end
    subject(:method) { FileUpdateJob.perform_later(token: start_page_token) }
    let(:start_page_token) { 1 }
    let(:change_list) { GoogleDrive.list_changes(start_page_token, 5) }
    let!(:files_that_were_changed) do
      change_list&.changes&.map do |change|
        create :file_items_base, google_drive_id: change.file_id
      end
    end

    it 'calls FileItems::Base.update_from_change once for every change' do
      expect(FileItems::Base).to receive(:update_from_change)
        .exactly(change_list.changes.count).times
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
end
