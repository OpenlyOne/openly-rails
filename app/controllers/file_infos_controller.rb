# frozen_string_literal: true

# Controller for project file infos
class FileInfosController < ApplicationController
  include CanSetProjectContext
  include ProjectLockable

  # Execute without lock or render/redirect delay
  before_action :set_project

  around_action :wrap_action_in_project_lock

  # Execute with lock and render/redirect delay
  before_action :set_project_context
  before_action :set_file_id
  before_action :set_current_file_diff
  before_action :set_file_versions
  before_action :set_file

  def index; end

  private

  # Attempt to find the file diff of stage (base) and last revision
  # (differentiator)
  def set_current_file_diff
    @current_file_diff = @project.repository
                                 .stage
                                 .diff(@project.repository.revisions.last)
                                 .diff_file(@file_id)
    # preload ancestors while in lock
    @current_file_diff.ancestors_of_file
  rescue ActiveRecord::RecordNotFound
    @current_file_diff = nil
  end

  # Set @file_id from params
  def set_file_id
    @file_id = params[:id]
  end

  # Find file in stage or version history
  def set_file
    # Set the file from current_file_diff OR
    @file = @current_file_diff&.file_is_or_was

    # Set file to most recent version (unless it's already been set because it
    # exists in stage)
    @file ||= @file_versions&.first&.file_is_or_was

    # Raise error if file has not been found in either stage or history
    raise ActiveRecord::RecordNotFound if @file.nil?
  end

  # Load file history
  def set_file_versions
    # Find past versions of file
    # TODO@performance: PRELOAD revision diffs, file diffs, and ancestors of
    # =>                files. Loading those in the view is bad practice and
    # =>                unnecessary N+1 queries.
    # TODO: Exclude files that were not 'changed?'
    # TODO: One day this should be @file.versions or Project.find_file_by_id(id)
    # =>    which then returns the last version of the file
    @file_versions =
      @project.git_revisions.all_as_diffs.map do |revision_diff|
        revision_diff.changed_files_as_diffs.find { |diff| diff.id == @file_id }
      end

    # Eliminate nil values
    @file_versions.compact!
  end
end
