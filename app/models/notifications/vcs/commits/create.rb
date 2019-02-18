# frozen_string_literal: true

module Notifications
  module VCS
    module Commits
      # Helper for commit notifications
      class Create
        include Rails.application.routes.url_helpers
        attr_accessor :commit
        attr_writer :source

        def initialize(commit, source: nil)
          self.commit = commit
          self.source = source
        end

        # The path to the notifying object
        def path
          profile_project_revisions_path(project.owner, project)
        end

        # The recipients for this notification
        def recipients
          recipient_users.map(&:account)
        end

        # The source/originator for this notification
        def source
          @source ||= commit.author
        end

        # The notification's title
        def title
          "#{source.name} created a revision in #{project.title}"
        end

        private

        def project
          Project.find_by_repository_id(commit.repository.id)
        end

        def collaborators_in_project
          [project.owner] + project.collaborators.includes(:account)
        end

        def recipient_users
          (collaborators_in_project - [commit.author]).uniq
        end
      end
    end
  end
end
