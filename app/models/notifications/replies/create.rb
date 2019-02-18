# frozen_string_literal: true

module Notifications
  module Replies
    # Helper for replies notifications
    class Create
      include Rails.application.routes.url_helpers
      attr_accessor :reply
      attr_writer :source

      delegate :contribution, to: :reply
      delegate :project, to: :contribution
      delegate :repliers, to: :contribution, prefix: true

      def initialize(reply, source: nil)
        self.reply = reply
        self.source = source
      end

      # The path to the notifying object
      def path
        profile_project_contribution_replies_path(
          project.owner, project, contribution, anchor: "reply-#{reply.id}"
        )
      end

      # The recipients for this notification
      def recipients
        recipient_users.map(&:account)
      end

      # The source/originator for this notification
      def source
        @source ||= reply.author
      end

      # The notification's title
      def title
        "#{source.name} replied to #{contribution.title}"
      end

      private

      def collaborators_in_project
        [project.owner] + project.collaborators.includes(:account)
      end

      def recipient_users
        (collaborators_in_project +
         contribution_repliers.includes(:account) +
         [contribution.creator] -
         [reply.author]).uniq
      end
    end
  end
end
