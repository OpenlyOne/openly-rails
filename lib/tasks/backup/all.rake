# frozen_string_literal: true

desc 'Backup: Backup the database and attachments'
namespace :backup do
  task all: ['backup:database', 'backup:attachments']
end
