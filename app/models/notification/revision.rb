# frozen_string_literal: true

class Notification
  # Helper for revision notifications
  class Revision
    include Rails.application.routes.url_helpers
    attr_accessor :revision

    def initialize(revision)
      self.revision = revision
    end

    # The path to the notifying object
    def path
      profile_project_revisions_path(revision.project.owner, revision.project)
    end

    # The recipients for this notification
    def recipients
      recipient_users.map(&:account)
    end

    # The source/originator for this notification
    def source
      revision.author
    end

    private

    def project
      revision.project
    end

    def collaborators_in_project
      [project.owner] + project.collaborators.includes(:account)
    end

    def recipient_users
      (collaborators_in_project - [revision.author]).uniq
    end
  end
end
