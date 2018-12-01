# frozen_string_literal: true

RSpec.describe Project::Setup, type: :model, vcr: true do
  subject(:setup) { build :project_setup }
  let(:project)   { setup.project }

  before  { prepare_google_drive_test(api_connection) }
  after   { tear_down_google_drive_test(api_connection) }

  let(:mime_type)         { folder_type }
  let(:folder_type)       { Providers::GoogleDrive::MimeType.folder }
  let(:document_type)     { Providers::GoogleDrive::MimeType.document }
  let(:user_acct)         { ENV['GOOGLE_DRIVE_USER_ACCOUNT'] }
  let(:tracking_acct)     { ENV['GOOGLE_DRIVE_TRACKING_ACCOUNT'] }
  let(:api_connection) do
    Providers::GoogleDrive::ApiConnection.new(user_acct)
  end
  let(:share_folder) do
    api_connection
      .share_file(google_drive_test_folder_id, tracking_acct)
  end
  let(:link) do
    Providers::GoogleDrive::Link.for(remote_file_id: remote_root.id,
                                     mime_type: folder_type)
  end

  # share test folder
  before { share_folder }

  # Create folder
  let!(:remote_root) do
    Providers::GoogleDrive::FileSync.create(
      name: 'Test File',
      parent_id: google_drive_test_folder_id,
      mime_type: mime_type,
      api_connection: api_connection
    )
  end

  before { setup.link = link }

  describe '#begin(attributes)', :delayed_job do
    before { setup.begin(link: link) }

    it 'sets root folder' do
      expect(project.staged_files.root).to be_present
      expect(project.staged_files.root.remote_file_id).to eq remote_root.id
    end

    it 'creates a FolderImportJob' do
      expect(setup.folder_import_jobs.count).to eq 1
    end

    it 'creates a SetupCompletionCheckJob' do
      expect(setup.setup_completion_check_jobs.count).to eq 1
    end
  end

  describe '#check_if_complete', :delayed_job do
    let(:hook) { nil }

    before { setup.begin(link: link) }
    before { hook }
    before { setup.check_if_complete }

    it { expect(setup).not_to be_completed }

    context 'when all FileImportJobs are gone (processed)' do
      let(:hook) { setup.folder_import_jobs.delete_all }

      it { expect(setup).to be_completed }

      it 'creates an origin revision' do
        expect(project.revisions).to be_any
        expect(project.revisions.first.title).to eq 'Import Files'
      end
    end
  end

  describe '#destroy', :delayed_job do
    before { setup.begin(link: link) }
    before { setup.destroy }

    it 'destroys all jobs' do
      expect(Delayed::Job.count).to eq 0
    end
  end

  describe 'validations' do
    context 'when link to google drive folder is valid' do
      it 'is valid' do
        is_expected.to be_valid
      end
    end

    context 'when link ends with ?usp=sharing' do
      let(:raw_link) do
        Providers::GoogleDrive::Link.for(remote_file_id: remote_root.id,
                                         mime_type: folder_type)
      end
      let(:link) { "#{raw_link}?usp=sharing" }

      it 'is valid' do
        is_expected.to be_valid
      end
    end

    context 'when link is drive.google.com/open?id=...' do
      let(:link) { "https://drive.google.com/open?id=#{remote_root.id}" }

      it 'is valid' do
        is_expected.to be_valid
      end
    end

    context 'when link to google drive folder is invalid' do
      let(:link) { 'https://invalid-folder-link' }

      it 'adds an error' do
        is_expected.to be_invalid
        expect(setup.errors[:link])
          .to include 'appears not to be a valid Google Drive link'
      end
    end

    context 'when link to google drive folder is inaccessible' do
      let(:share_folder) { nil }

      it 'adds an error' do
        is_expected.to be_invalid
        expect(setup.errors[:link])
          .to include 'appears to be inaccessible. Have you shared the '\
                      'resource with '\
                      "#{Settings.google_drive_tracking_account}?"
      end
    end

    context 'when link looks like google drive folder but has ID of doc' do
      let(:mime_type) { document_type }

      it 'adds an error' do
        is_expected.to be_invalid
        expect(setup.errors[:link])
          .to include 'appears not to be a Google Drive folder'
      end
    end

    context 'when link is a google drive doc' do
      let(:mime_type) { document_type }
      let(:link) do
        Providers::GoogleDrive::Link.for(remote_file_id: remote_root.id,
                                         mime_type: mime_type)
      end

      it 'adds an error' do
        is_expected.to be_invalid
        expect(setup.errors[:link])
          .to include 'appears not to be a Google Drive folder'
      end
    end
  end
end
