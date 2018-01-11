# frozen_string_literal: true

# Expect the controller action to call #set_project and #set_project_context
# methods required to correctly render the project head
RSpec.shared_examples 'setting project context' do
  after { run_request }
  it    { is_expected.to receive(:set_project).and_call_original }
  it    { is_expected.to receive(:set_project_context) }
end
