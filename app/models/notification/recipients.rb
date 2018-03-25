# frozen_string_literal: true

class Notification
  # Select recipients for the notifying object
  class Recipients
    def self.for_revision(revision)
      collaborators = collaborators_in_project(revision.project)
      recipient_users = (collaborators - [revision.author]).uniq
      recipient_users.map(&:account)
    end

    def self.collaborators_in_project(project)
      [project.owner] + project.collaborators.includes(:account)
    end
  end
end
