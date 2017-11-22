# frozen_string_literal: true

# Controller for project folders
class FoldersController < ApplicationController
  before_action :set_project
  before_action :set_folder
  before_action :set_files

  def root
    render 'show'
  end

  def show; end

  private

  def set_project
    @project = Project.find(params[:profile_handle], params[:project_slug])
  end

  def set_folder
    @folder =
      if params[:google_drive_id]
        FileItems::Folder.find_by!(
          project: @project,
          google_drive_id: params[:google_drive_id]
        )
      else
        # raise 404 unless @folder is set
        @project.root_folder || (raise ActiveRecord::RecordNotFound)
      end
  end

  def set_files
    @files = @folder.children.order("CASE
      WHEN file_items.mime_type = 'application/vnd.google-apps.folder' THEN '1'
      ELSE '2'
    END", 'file_items.name::bytea')
  end
end
