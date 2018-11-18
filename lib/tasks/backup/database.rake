# frozen_string_literal: true

desc 'Backup: Create a backup of the database'
namespace :backup do
  task database: ['database:capture']
end
