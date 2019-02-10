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
                       association: :new_version
  Bullet.add_whitelist type: :unused_eager_loading, class_name: 'VCS::FileDiff',
                       association: :old_version

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
                       class_name: 'VCS::Version',
                       association: :backup

  # Bullet complains about Ahoy including user
  Bullet.add_whitelist type: :unused_eager_loading,
                       class_name: 'Ahoy::Visit',
                       association: :user

  Bullet.add_whitelist type: :unused_eager_loading,
                       class_name: 'FileResources::GoogleDrive',
                       association: :parent

  Bullet.add_whitelist type: :unused_eager_loading,
                       class_name: 'VCS::FileInBranch',
                       association: :thumbnail

  Bullet.add_whitelist type: :unused_eager_loading,
                       class_name: 'VCS::FileInBranch',
                       association: :current_version

  Bullet.add_whitelist type: :unused_eager_loading,
                       class_name: 'VCS::CommittedFile',
                       association: :version

  Bullet.add_whitelist type: :unused_eager_loading,
                       class_name: 'VCS::Version',
                       association: :content

  # Bullet complains in admin panel when showing # of project collaborators
  Bullet.add_whitelist type: :unused_eager_loading,
                       class_name: 'Project',
                       association: :collaborators

  # Bullet complains in admin panel when showing # of project collaborators
  Bullet.add_whitelist type: :unused_eager_loading,
                       class_name: 'Project',
                       association: :projects_collaborators

  # Bullet complains on the profile page when eager loading master branch but
  # not actually showing any uncaptured changes indicator
  Bullet.add_whitelist type: :unused_eager_loading,
                       class_name: 'Project',
                       association: :master_branch
end
