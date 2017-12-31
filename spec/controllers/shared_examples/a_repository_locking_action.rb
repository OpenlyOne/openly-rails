# frozen_string_literal: true

# Expect the controller action to lock the project's repository and delay
# rendering until the lock has completed
# Used to test the ProjectLockable controller concern.
RSpec.shared_examples 'a repository locking action' do
  render_views

  it 'does not render or redirect until lock has completed' do
    allow_any_instance_of(VersionControl::Repository)
      .to receive(:lock) do |*_args, &first_call_to_lock|

      # stub subsequent calls
      allow_any_instance_of(VersionControl::Repository)
        .to receive(:lock) do |*_args, &subsequent_call_to_lock|
        subsequent_call_to_lock.call
      end

      first_call_to_lock.call

      # Once the first call to lock complete, we want no further calls to lock
      # If any other calls to lock occur, then these calls are happening outside
      # of our controller action and should be fixed.
      expect_any_instance_of(VersionControl::Repository).not_to receive(:lock)

      # Once the first call to lock completes, the response body must still be
      # nil!
      expect(controller.response_body).to be nil
    end.once

    run_request

    # at the very end, the response must be present
    expect(response.body).to be_present
  end
end
