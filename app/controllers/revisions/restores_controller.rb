# frozen_string_literal: true

module Revisions
  # File browsing actions for a project revision
  class RestoresController < ApplicationController
    include CanSetProjectContext

    before_action :set_revision
    before_action :authenticate_account!
    before_action :set_project_where_setup_is_complete
    before_action :authorize_project_access
    before_action :authorize_action

    # TODO: Extract logic out of controller
    def create
      current_commit = build_commit_with_files_staged_in_branch

      commit_to_restore = @revision

      diffs = calculate_diffs(new_commit: commit_to_restore,
                              old_commit: current_commit)

      diffs_to_restore = diffs

      # TODO: Optimize by only doing this for diffs_to_restore that are folders
      # =>    and additions
      until diffs_to_restore.empty?
        diffs_to_restore.each do |diff|
          # check if the diff has a parent
          next unless diff_without_parent?(diff, diffs_to_restore)

          # perform restoration
          VCS::Operations::FileRestore
            .new(
              snapshot: diff.new_snapshot,
              file_record_id: diff.current_or_previous_snapshot.file_record_id,
              target_branch: @master_branch
            ).restore
          # remove diff from list
          diffs_to_restore.delete(diff)
        end
      end

      redirect_to root_folder_path, notice: 'Revision successfully restored.'
    end

    private

    rescue_from CanCan::AccessDenied do |exception|
      can_can_access_denied(exception)
    end

    def authorize_action
      authorize! :restore_revision, @project
    end

    def build_commit_with_files_staged_in_branch
      VCS::Commit
        .create(branch: @master_branch,
                parent: @master_branch.commits.last,
                author: current_user)
        .tap(&:commit_all_files_staged_in_branch)
    end

    def can_can_access_denied(exception)
      super || redirect_to(revision_root_folder_path, alert: exception.message)
    end

    def calculate_diffs(new_commit:, old_commit:)
      VCS::Operations::FileDiffsCalculator
        .new(commit: new_commit, parent_commit: old_commit)
        .file_diffs
    end

    def diff_without_parent?(diff, all_diffs)
      return true if diff.current_snapshot.nil?

      all_diffs.none? do |other_diff|
        diff.current_file_record_parent_id == other_diff.current_file_record_id
      end
    end

    def root_folder_path
      profile_project_root_folder_path(@project.owner, @project)
    end

    def revision_root_folder_path
      profile_project_revision_root_folder_path(@project.owner, @project,
                                                @revision.id)
    end

    def set_revision
      @revision = VCS::Commit.find(params[:revision_id])
    end
  end
end
