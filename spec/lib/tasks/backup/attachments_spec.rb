# frozen_string_literal: true

require 'lib/shared_contexts/rake.rb'

RSpec.describe 'backup:attachments' do
  include_context 'rake'

  subject(:run_task) { task.invoke }

  let(:tasks_to_load) do
    ['backup:attachments:capture',
     'backup:attachments:create_directory']
  end
  let(:backups)      { Pathname.new(backups_path).children }
  let(:backups_path) { Rails.root.join(Settings.backup_storage, 'attachments') }

  before { allow(STDOUT).to receive(:puts) }

  let(:profile_picture) do
    File.new(
      Rails.root.join('spec', 'support', 'fixtures', 'profiles', 'picture.jpg')
    )
  end

  before { create(:user, picture: profile_picture) }

  it 'creates a backup' do
    run_task
    expect(backups.count).to eq 1
  end

  context 'when creating a second backup' do
    include ActiveSupport::Testing::TimeHelpers

    before { task.invoke }

    it 'does not overwrite first backup' do
      travel 1.day do
        reenable_all_tasks
        run_task
      end
      expect(backups.count).to eq 2
    end
  end

  context 'when attachment folder does not exist' do
    before { FileUtils.rm_rf Rails.root.join(Settings.attachment_storage) }

    it { expect { run_task }.not_to raise_error }
  end
end
