# frozen_string_literal: true

require 'routing/shared_examples/routing_for_discussions.rb'

RSpec.describe 'routes for issues', type: :routing do
  it_should_behave_like 'routing for discussions', 'issues'
end
