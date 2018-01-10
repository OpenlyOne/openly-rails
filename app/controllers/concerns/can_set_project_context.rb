# frozen_string_literal: true

# Define setter method for setting the instance variables needed to correctly
# display the project header (@project, @roo_folder, @has_revisions, ...)
module CanSetProjectContext
  extend ActiveSupport::Concern

  included do
    include ProjectLockable
  end

  private

  # Find and set project. Raise 404 if project does not exist
  def set_project
    @project = Project.find(params[:profile_handle], params[:project_slug])
  end

  # Set instance variables needed to render the project header on the top of
  # the page (link to Files, link to Google Drive, link to revisions)
  def set_project_context
    _set_root_folder
    _set_has_revisions
  end

  def _set_root_folder
    @root_folder = @project.files.root
  end

  def _set_has_revisions
    # TODO: Add #revisions directly to project (delegate to repository)
    # TODO: Add method #any? to RevisionsCollection
    # Final output: @project.revisions.any?
    @has_revisions = @project.repository.revisions.last.present?
  end
end
