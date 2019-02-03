# frozen_string_literal: true

# Controller for project file infos
class FileChangesController < Abstract::FileChangesController
  private

  def set_branch
    @branch = @master_branch
  end
end
