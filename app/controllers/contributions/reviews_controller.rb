# frozen_string_literal: true

module Contributions
  # Controller for reviewing changes suggested by a contribution
  class ReviewsController < ApplicationController
    include CanSetProjectContext

    before_action :set_project_where_setup_is_complete
    before_action :authorize_project_access
    before_action :set_contribution

    def show
      build_revision
    end

    private

    def branch
      @contribution.branch
    end

    # TODO: Extract author out of commits
    def build_revision
      new_revision =
        branch.commits.create!(
          branch: branch,
          parent: @master_branch.commits.last,
          author: @contribution.creator,
          is_published: false
        )

      new_revision.commit_all_files_in_branch
      new_revision.generate_diffs

      find_revision_by_id(new_revision.id)
    end

    def find_revision_by_id(id)
      @revision =
        VCS::Commit
        .preload_file_diffs_with_versions
        .find_by!(id: id, branch: branch, author: @contribution.creator)
    end

    def set_contribution
      @contribution = @project.contributions.find(params[:contribution_id])
    end
  end
end
