# frozen_string_literal: true

module Notifications
  module Contributions
    # Helper for contribution notifications
    class Accept
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
        @source ||= contribution.acceptor
      end

      # The notification's title
      def title
        "#{source.name} accepted a contribution in #{project.title}"
      end

      private

      def collaborators_in_project
        [project.owner] + project.collaborators.includes(:account)
      end

      def recipient_users
        (collaborators_in_project +
         [contribution.creator] -
         [contribution.acceptor]).uniq
      end
    end
  end
end
