# frozen_string_literal: true

desc 'Backup: Create a backup of the (Paperclip) attachments'
namespace :backup do
  task attachments: ['attachments:capture']
end
