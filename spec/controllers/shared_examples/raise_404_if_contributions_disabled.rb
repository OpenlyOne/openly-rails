# frozen_string_literal: true

# Expect ActiveRecord::RecordNotFound error (404) when the contributions feature
# is disabled
RSpec.shared_examples 'raise 404 if contributions disabled' do
  before { project.update_attribute(:are_contributions_enabled, false) }

  it 'raises 404 when contributions feature is disabled' do
    expect { run_request }.to raise_error ActiveRecord::RecordNotFound
  end
end
