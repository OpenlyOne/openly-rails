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

  Bullet.add_whitelist type: :unused_eager_loading, class_name: 'FileDiff',
                       association: :previous_snapshot
end
