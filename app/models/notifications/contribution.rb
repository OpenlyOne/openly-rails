# frozen_string_literal: true

module Notifications
  # Helper for contribution notifications
  class Contribution
    include Rails.application.routes.url_helpers
    attr_accessor :contribution
    attr_writer :source

    delegate :project, to: :contribution

    def initialize(contribution, source: nil)
      self.contribution = contribution
      self.source = source
    end

    # The path to the notifying object
    def path
      profile_project_contribution_path(project.owner, project, contribution)
    end

    # The recipients for this notification
    def recipients
      recipient_users.map(&:account)
    end

    # The source/originator for this notification
    def source
      @source ||= contribution.creator
    end

    # The notification's title
    def title
      "#{source.name} created a contribution in #{project.title}"
    end

    private

    def collaborators_in_project
      [project.owner] + project.collaborators.includes(:account)
    end

    def recipient_users
      (collaborators_in_project - [contribution.creator]).uniq
    end
  end
end
