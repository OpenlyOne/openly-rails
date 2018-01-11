# frozen_string_literal: true

# Define helpers needed for project revisions
module RevisionHelper
  # If revision includes :last_revision_id error, remove that error and replace
  # with detailed explanation about why committing the changes has failed and
  # the process must be started over
  def format_revision_errors!(revision, link_to_start_over)
    return unless revision.errors.include? :last_revision_id

    # Delete the original error
    revision.errors.delete :last_revision_id

    # And add an improved error explanation to :base
    detailed_error_message =
      'Someone else has committed changes to this project since you ' \
      'started reviewing changes. To prevent you and your team from ' \
      "overwriting each other's changes, you cannot commit the changes you " \
      'are currently reviewing. ' \
      "#{link_to 'Click here to start over', link_to_start_over}."
    revision.errors[:base] << detailed_error_message.html_safe
  end
end
