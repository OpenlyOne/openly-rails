# frozen_string_literal: true

# Drop the notification_channels table
class DropNotificationChannels < ActiveRecord::Migration[5.1]
  def up
    drop_table 'notification_channels'
  end

  # rubocop:disable Metrics/MethodLength
  def down
    create_table 'notification_channels' do |t|
      t.bigint 'project_id', null: false
      t.bigint 'file_item_id', null: false
      t.integer 'status', default: 0, null: false
      t.datetime 'expires_at'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.index ['file_item_id'],
              name: 'index_notification_channels_on_file_item_id'
      t.index ['project_id'], name: 'index_notification_channels_on_project_id'
      t.index ['status'], name: 'index_notification_channels_on_status'
    end
  end
  # rubocop:enable Metrics/MethodLength
end
