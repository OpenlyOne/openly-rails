# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database
# with its default values. The data can then be loaded with the rails db:seed
# command (or created alongside the database with db:setup).

require 'faker'
require 'factory_girl_rails'

# Create three users
%w[alice bob carla].each do |username|
  account = Account.new email: "#{username}@upshift.one", password: 'password'
  account.build_user name: username.capitalize
  account.user.build_handle identifier: username
  account.save

  # Create three projects per user
  3.times.with_index do |i|
    FactoryGirl.create :project, owner: account.user, slug: "project-#{i + 1}"
  end
end
