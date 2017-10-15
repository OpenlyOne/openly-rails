# frozen_string_literal: true

require 'features/shared_examples/implementing_discussion_features.rb'

feature 'Discussions::Question' do
  it_should_behave_like 'implementing discussion features', 'questions'
end
