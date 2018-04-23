# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

# config valid only for current version of Capistrano
lock '3.10.1'

# Load default settings
require 'config'
Config.load_and_set_settings(Config.setting_files('config', fetch(:env)))

server Settings.app_domain, port: 22, roles: %i[web app db], primary: true

set :repo_url,        'git@github.com:UpshiftOne/upshift.git'
set :application,     'upshift'
set :user,            ENV['DEPLOY_USER']
set :puma_threads,    [4, 16]
set :puma_workers,    0

# Don't change these unless you know what you're doing
set :pty,             true
set :use_sudo,        false
set :stage,           :production
set :deploy_via,      :remote_cache
set :deploy_to,       "/var/apps/#{fetch(:application)}"
set :puma_bind,
    "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}-puma.sock"
set :puma_state,      "#{shared_path}/tmp/pids/puma.state"
set :puma_pid,        "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.error.log"
set :puma_error_log,  "#{release_path}/log/puma.access.log"
set :ssh_options,
    forward_agent:  true,
    user:           fetch(:user),
    keys:           %w[~/.ssh/id_rsa.pub]
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true

# Communicate deploy information to Rollbar
set :rollbar_token, ENV['ROLLBAR_ACCESS_TOKEN']
set :rollbar_env, (proc { fetch :stage })
set :rollbar_role, (proc { :app })

## Defaults:
# set :scm,           :git
# set :branch,        :master
# set :format,        :pretty
# set :log_level,     :debug
# set :keep_releases, 5

## Linked Files & Directories (Default None):
# set :linked_files, %w{config/database.yml}
# Must link tmp/pids to allow DelayedJob to survive deployments,
# see: https://github.com/platanus/capistrano3-delayed-job/pull/22
set :linked_dirs,
    %W[public/.well-known
       tmp/pids
       #{Settings.attachment_storage}]

namespace :puma do
  desc 'Create Directories for Puma Pids and Socket'
  task :make_dirs do
    on roles(:app) do
      execute "mkdir #{shared_path}/tmp/sockets -p"
      execute "mkdir #{shared_path}/tmp/pids -p"
    end
  end

  before :start, :make_dirs
end

# Refresh missing styles for paperclip
namespace :paperclip do
  desc 'build missing paperclip styles'
  task :build_missing_styles do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'paperclip:refresh:missing_styles'
        end
      end
    end
  end
end

desc 'Invoke a rake command on the remote server'
task :invoke, [:command] => 'deploy:set_rails_env' do |_task, args|
  on roles(:app) do
    within release_path do
      with rails_env: fetch(:rails_env) do
        rake args[:command]
      end
    end
  end
end

namespace :deploy do
  desc 'Make sure local git is in sync with remote.'
  task :check_revision do
    on roles(:app) do
      unless `git rev-parse HEAD` == `git rev-parse origin/master`
        abort 'Error: HEAD is not the same as origin/master'
      end
    end
  end

  desc 'Initial Deploy'
  task :initial do
    on roles(:app) do
      before 'deploy:restart', 'puma:start'
      invoke 'deploy'
    end
  end

  desc 'Generate static 500.html page'
  task :generate_500_html do
    on roles(:web) do |host|
      public_500_html = File.join(release_path, 'public/500.html')
      execute :curl,
              '-k',
              "https://#{host.hostname}/500", "> #{public_500_html}"
    end
  end

  before :starting,       :check_revision
  after  :finishing,      :compile_assets
  after  :migrate,        'paperclip:build_missing_styles'
  after  :finishing,      :cleanup
  after  :published,      :generate_500_html
end

# rubocop:enable Metrics/BlockLength

# ps aux | grep puma    # Get puma pid
# kill -s SIGUSR2 pid   # Restart puma
# kill -s SIGTERM pid   # Stop puma
