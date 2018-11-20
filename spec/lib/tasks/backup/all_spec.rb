# frozen_string_literal: true

require 'lib/shared_contexts/rake.rb'

RSpec.describe 'backup:all' do
  include_context 'rake'

  subject(:run_task) { task.invoke }

  let(:tasks_to_load) do
    ['backup:database',
     'backup:database:capture',
     'backup:database:create_directory',
     'backup:attachments',
     'backup:attachments:capture',
     'backup:attachments:create_directory']
  end
  let(:database_backups)    { Pathname.new(database_backups_path).children }
  let(:attachment_backups)  { Pathname.new(attachment_backups_path).children }
  let(:backups_path)        { Rails.root.join(Settings.backup_storage) }
  let(:database_backups_path)   { backups_path.join('database') }
  let(:attachment_backups_path) { backups_path.join('attachments') }

  let(:attachments_path) { Rails.root.join(Settings.attachment_storage) }
  let(:profile_picture) do
    File.new(
      Rails.root.join('spec', 'support', 'fixtures', 'profiles', 'picture.jpg')
    )
  end

  before { allow(STDOUT).to receive(:puts) }

  context 'when restoring backup', :no_db_cleaner, :slow do
    before do
      # create backup
      create_list(:account, 3)
      Profiles::User.find_each do |user|
        user.update(picture: profile_picture)
      end
      run_task

      # clear database
      ActiveRecord::Base.remove_connection
      system('rake db:drop RAILS_ENV=test', out: File::NULL)
      system('rake db:create RAILS_ENV=test', out: File::NULL)

      # clear attachments
      FileUtils.rm_rf attachments_path
    end

    # Ensure state restoration
    after do
      ActiveRecord::Base.remove_connection
      system('rake db:drop RAILS_ENV=test', out: File::NULL)
      system('rake db:create RAILS_ENV=test', out: File::NULL)
      system('rake db:schema:load RAILS_ENV=test', out: File::NULL)
      ActiveRecord::Base.establish_connection
    end

    it 'succeeds' do
      # import database
      `pg_restore \
       -d #{Rails.configuration.database_configuration['test']['database']} \
       -1 \
       #{database_backups.first.to_s}`

      # import images
      FileUtils.copy_entry(
        attachment_backups.first.to_s,
        attachments_path,
        preserve: true
      )

      # reconnect to database
      ActiveRecord::Base.establish_connection

      expect(Account.count).to eq 3
      Profiles::User.find_each do |user|
        expect(user.picture).to be_exists
      end
    end
  end
end
