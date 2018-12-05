# frozen_string_literal: true

# Controller for project file infos
class FileChangesController < ApplicationController
  include CanSetProjectContext

  before_action :set_project_where_setup_is_complete
  before_action :authorize_project_access
  before_action :set_file_diff
  before_action :ensure_modification
  before_action :ensure_content_change

  def show; end

  private

  # Raise error unless we have a modification
  def ensure_modification
    raise ActiveRecord::RecordNotFound unless @file_diff.modification?
  end

  # Raise error unless we have content change
  def ensure_content_change
    raise ActiveRecord::RecordNotFound unless @file_diff.content_change.present?
  end

  # Set the uncaptured file diff if file in branch has current or committed
  # version present
  def set_file_diff
    return unless file_in_branch.version.present?

    @file_diff = file_in_branch.diff
  end

  def file_in_branch
    @file_in_branch ||=
      @master_branch
      .files
      .without_root
      .find_by_hashed_file_id!(params[:id])
  end
end
