# frozen_string_literal: true

if defined? Bullet

  # show warnings in development env
  if Rails.env.development?
    Bullet.enable = true
    Bullet.bullet_logger = true
    Bullet.alert = true
    Bullet.console = true
    Bullet.rails_logger = true
    Bullet.add_footer = true

  # raise errors in test environment
  elsif Rails.env.test?
    Bullet.enable = true
    Bullet.bullet_logger = true
    Bullet.raise = true
  end

  Bullet.add_whitelist type: :unused_eager_loading, class_name: 'VCS::FileDiff',
                       association: :new_snapshot
  Bullet.add_whitelist type: :unused_eager_loading, class_name: 'VCS::FileDiff',
                       association: :old_snapshot

  Bullet.add_whitelist type: :unused_eager_loading,
                       class_name: 'Profiles::User',
                       association: :account

  # Bullet complains because we're manually preloading thumbnail associations
  Bullet.add_whitelist type: :n_plus_one_query,
                       class_name: 'FileResource::Snapshot',
                       association: :thumbnail

  # Bullet complains about RevisionsController eager loading
  Bullet.add_whitelist type: :unused_eager_loading,
                       class_name: 'Revision',
                       association: :file_diffs

  # Bullet complains when we browse committed files that all have no backups
  Bullet.add_whitelist type: :unused_eager_loading,
                       class_name: 'VCS::FileSnapshot',
                       association: :backup

  # Bullet complains about Ahoy including user
  Bullet.add_whitelist type: :unused_eager_loading,
                       class_name: 'Ahoy::Visit',
                       association: :user

  Bullet.add_whitelist type: :unused_eager_loading,
                       class_name: 'FileResources::GoogleDrive',
                       association: :parent

  Bullet.add_whitelist type: :unused_eager_loading,
                       class_name: 'VCS::StagedFile',
                       association: :thumbnail

  Bullet.add_whitelist type: :unused_eager_loading,
                       class_name: 'VCS::StagedFile',
                       association: :current_snapshot

  Bullet.add_whitelist type: :unused_eager_loading,
                       class_name: 'VCS::CommittedFile',
                       association: :file_snapshot

  Bullet.add_whitelist type: :unused_eager_loading,
                       class_name: 'VCS::FileSnapshot',
                       association: :content
end
