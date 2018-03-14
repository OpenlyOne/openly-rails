# frozen_string_literal: true

# Controller for project file infos
class FileInfosController < ApplicationController
  include CanSetProjectContext

  before_action :set_project_where_setup_is_complete
  before_action :authorize_project_access
  before_action :set_staged_file_diff
  before_action :set_committed_file_diffs
  before_action :set_file
  # TODO: Find way to not manually set provider for all children while still
  #       avoiding N+1 query
  before_action :set_provider_committed_file_diffs
  before_action :set_user_can_force_sync_files

  def index; end

  private

  # Attempt to find the file diff of stage (base) and last revision
  # (differentiator)
  def set_staged_file_diff
    @staged_file_diff = Stage::FileDiff.find_by!(external_id: params[:id],
                                                 project: @project)
  rescue ActiveRecord::RecordNotFound
    @staged_file_diff = nil
  end

  def file_resource_id
    @file_resource_id ||=
      FileResource.find_by!(external_id: params[:id]).id
  end

  # Find file in stage or version history
  def set_file
    # Set the file from staged_file_diff OR
    @file = @staged_file_diff&.current_or_previous_snapshot

    # Set file to most recent version (unless it's already been set because it
    # exists in stage)
    @file ||= @committed_file_diffs&.first&.current_or_previous_snapshot

    # Raise error if file has not been found in either stage or history
    raise ActiveRecord::RecordNotFound if @file.nil?
  end

  # Load file history
  def set_committed_file_diffs
    @committed_file_diffs =
      FileDiff
      .includes(:current_snapshot, :previous_snapshot, revision: [:author])
      .where(revisions: { project: @project, is_published: true },
             file_resource_id: file_resource_id)
      .merge(Revision.order(id: :desc))
  end

  def set_provider_committed_file_diffs
    @committed_file_diffs.each do |diff|
      diff.provider = @project.root_folder.provider
    end
  end

  def set_user_can_force_sync_files
    @user_can_force_sync_files = can?(:force_sync, @project)
  end
end
