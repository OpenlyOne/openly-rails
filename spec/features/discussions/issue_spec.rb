# frozen_string_literal: true

require 'features/shared_examples/implementing_discussion_features.rb'

feature 'Discussions::Issues' do
  it_should_behave_like 'implementing discussion features', 'issues'
end
