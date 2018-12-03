# frozen_string_literal: true

# Controller for project file infos
class FileInfosController < ApplicationController
  include CanSetProjectContext

  before_action :set_project_where_setup_is_complete
  before_action :authorize_project_access
  before_action :set_uncaptured_file_diff
  before_action :set_committed_file_diffs
  before_action :set_file
  before_action :set_parent_in_branch, if: :uncaptured_file_diff_present?
  before_action :set_user_can_force_sync_files
  before_action :preload_backups_for_committed_file_diffs

  def index; end

  private

  # Attempt to find the file diff of stage (base) and last revision
  # (differentiator)
  def set_uncaptured_file_diff
    file_in_branch = @master_branch.files
                                   .without_root
                                   .joins_version
                                   .find_by(file_id: file_id)

    @uncaptured_file_diff = file_in_branch&.diff(with_ancestry: true)
  rescue ActiveRecord::RecordNotFound
    @uncaptured_file_diff = nil
  end

  def file_id
    @file_id ||= @project.repository.file_versions
                         .find_by!(remote_file_id: params[:id]).file_id
  end

  def preload_backups_for_committed_file_diffs
    ActiveRecord::Associations::Preloader.new.preload(
      Array(@committed_file_diffs).flat_map(&:current_or_previous_version),
      :backup
    )
  end

  # Find file in stage or version history
  def set_file
    # Set the file from uncaptured_file_diff OR
    @file = @uncaptured_file_diff&.current_or_previous_version

    # Set file to most recent version (unless it's already been set because it
    # exists in stage)
    @file ||= @committed_file_diffs&.first&.current_or_previous_version

    # Raise error if file has not been found in either stage or history
    raise ActiveRecord::RecordNotFound if @file.nil?
  end

  # Load file history
  def set_committed_file_diffs
    @committed_file_diffs =
      VCS::FileDiff
      .includes(commit: [:author])
      .joins_current_or_previous_version
      .preload(:new_version, :old_version)
      .where(
        vcs_commits: { branch_id: @master_branch.id, is_published: true },
        current_or_previous_version: { file_id: file_id }
      ).merge(VCS::Commit.order(id: :desc))
  end

  # Set the parent of file in stage
  def set_parent_in_branch
    @parent_in_branch = @master_branch.files.find_by(file_id: @file.parent_id)
  end

  def set_user_can_force_sync_files
    @user_can_force_sync_files = can?(:force_sync, @project)
  end

  def uncaptured_file_diff_present?
    @uncaptured_file_diff.present?
  end
end
