# frozen_string_literal: true

module Abstract
  # Abstract super class for file infos controller used for project and
  # contributions
  class FileInfosController < ApplicationController
    include CanSetProjectContext

    before_action :set_project_where_setup_is_complete
    before_action :authorize_project_access
    before_action :set_object
    before_action :set_branch
    before_action :set_uncaptured_file_diff
    before_action :set_committed_file_diffs
    before_action :set_file
    before_action :set_parent_in_branch, if: :uncaptured_file_diff_present?
    before_action :set_user_can_view_file_in_branch
    before_action :set_user_can_force_sync_files
    before_action :set_user_can_restore_files
    before_action :preload_backups_for_committed_file_diffs

    def index
      render 'file_infos/index', locals: {
        path_parameters: path_parameters,
        file_infos_path: "#{link_path_prefix}file_infos_path",
        folder_path: "#{link_path_prefix}folder_path",
        root_folder_path: "#{link_path_prefix}root_folder_path"
      }
    end

    private

    # Set the uncaptured file diff if file in branch has current or committed
    # version present
    def set_uncaptured_file_diff
      return unless file_in_branch.version.present?

      @uncaptured_file_diff = file_in_branch.diff(with_ancestry: true)
    end

    def file_in_branch
      @file_in_branch ||=
        @branch
        .files
        .without_root
        .find_by_hashed_file_id_or_remote_file_id!(params[:id])
    end

    def preload_backups_for_committed_file_diffs
      ActiveRecord::Associations::Preloader.new.preload(
        Array(@committed_file_diffs).flat_map(&:current_or_previous_version),
        :backup
      )
    end

    # Find file in stage or version history
    # TODO: This needs major rework. Should probably move methods into
    # =>    FileInBranch model.
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
          current_or_previous_version: { file_id: file_in_branch.file_id }
        ).merge(VCS::Commit.order(id: :desc))
    end

    # Overwrite to set an object from params, such as a contribution
    def set_object; end

    # Set the parent of file in stage
    def set_parent_in_branch
      @parent_in_branch =
        @branch.files.find_by(file_id: @uncaptured_file_diff&.parent_id)
    end

    def uncaptured_file_diff_present?
      @uncaptured_file_diff.present?
    end
  end
end
