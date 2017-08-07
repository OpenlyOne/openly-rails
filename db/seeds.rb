# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database
# with its default values. The data can then be loaded with the rails db:seed
# command (or created alongside the database with db:setup).

require 'faker'
require 'factory_girl_rails'

5.times.with_index do |i|
  FactoryGirl.create(
    :account,
    email: "user#{i + 1}@upshift.one",
    password: 'password'
  )
end
