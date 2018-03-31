# frozen_string_literal: true

# Load DSL and set up stages
require 'capistrano/setup'

# Include default deployment tasks
require 'capistrano/deploy'

# Load ENV vars via Figaro
require 'figaro'
Figaro.application =
  Figaro::Application.new(
    environment: 'production',
    path: File.expand_path('config/application.yml', __dir__)
  )
Figaro.load

# Load the SCM plugin appropriate to your project:
#
# require 'capistrano/scm/hg'
# install_plugin Capistrano::SCM::Hg
# or
# require 'capistrano/scm/svn'
# install_plugin Capistrano::SCM::Svn
# or
require 'capistrano/scm/git'
install_plugin Capistrano::SCM::Git

# Include tasks from other gems included in your Gemfile
#
# For documentation on these, see for example:
#
#   https://github.com/capistrano/rvm
#   https://github.com/capistrano/rbenv
#   https://github.com/capistrano/chruby
#   https://github.com/capistrano/bundler
#   https://github.com/capistrano/rails
#   https://github.com/capistrano/passenger
#
require 'capistrano/rails'
require 'capistrano/bundler'
require 'capistrano/rvm'
require 'capistrano/puma'
require 'capistrano/rails/console'
# Default puma tasks
install_plugin Capistrano::Puma
require 'capistrano/figaro_yml'
# Communicate deploy information to Capistrano
require 'rollbar/capistrano3'
# DelayedJob tasks for Capistrano
require 'capistrano/delayed_job'

# Loads custom tasks from `lib/capistrano/tasks' if you have any defined.
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
