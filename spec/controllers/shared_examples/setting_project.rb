# frozen_string_literal: true

require 'controllers/shared_examples/raise_404_if_non_existent.rb'

# Expect ActiveRecord::RecordNotFound error (404) when profile or project does
# not exist
RSpec.shared_examples 'setting project' do
  it_should_behave_like 'raise 404 if non-existent', Profiles::Base
  it_should_behave_like 'raise 404 if non-existent', Project
end

# Expect ActiveRecord::RecordNotFound error (404) when profile or project does
# not exist, or project is not complete
RSpec.shared_examples 'setting project where setup is complete' do
  include_examples 'setting project'

  it_should_behave_like 'raise 404 if non-existent', 'completed project' do
    let(:object_class)  { nil }
    before              { Project::Setup.update_all(is_completed: false) }
  end
end
