# frozen_string_literal: true

require 'lib/shared_contexts/rake.rb'

RSpec.describe 'backup:database' do
  include_context 'rake'

  subject(:run_task) { task.invoke }

  let(:task_path) { "lib/tasks/#{task_name.tr(':', '/')}" }
  let(:depends_on_task_paths) do
    ['lib/tasks/backup/database/capture',
     'lib/tasks/backup/database/create_directory']
  end
  let(:backups)       { Pathname.new(backups_path).children }
  let(:backups_path)  { Rails.root.join(Settings.backup_storage, 'database') }

  before { allow(STDOUT).to receive(:puts) }

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
end
