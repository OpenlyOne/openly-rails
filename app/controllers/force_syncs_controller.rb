# frozen_string_literal: true

# Controller for force syncing files
class ForceSyncsController < ApplicationController
  include CanSetProjectContext

  before_action :set_project
  before_action :set_staged_file_diff
  before_action :set_file_resource

  def create
    @file.pull
    @file.pull_children if @file.folder?

    redirect_to file_info_path, notice: 'File successfully synced.'
  end

  private

  def file_id
    params[:id]
  end

  def file_info_path
    profile_project_file_infos_path(@project.owner, @project, file_id)
  end

  # Attempt to find the file diff of stage (base) and last revision
  # (differentiator)
  def set_staged_file_diff
    @staged_file_diff = Stage::FileDiff.find_by!(external_id: file_id,
                                                 project: @project)
  end

  # Set the file resource
  def set_file_resource
    @file = FileResources::GoogleDrive.find_by!(external_id: file_id)
  end
end
