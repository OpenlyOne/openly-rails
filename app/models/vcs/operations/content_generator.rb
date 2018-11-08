# frozen_string_literal: true

module VCS
  module Operations
    # Generate (find or create) VCS::Content based on the passed attributes
    class ContentGenerator
      # Attributes
      attr_accessor :repository, :remote_file_id, :remote_content_version_id

      # Initialize a new instance and generate content
      def self.generate(attributes)
        new(attributes).generate
      end

      def initialize(attributes)
        self.repository = attributes.fetch(:repository)
        self.remote_file_id = attributes.fetch(:remote_file_id)
        self.remote_content_version_id =
          attributes.fetch(:remote_content_version_id)
      end

      # Find or create the VCS::Content
      def generate
        remote_content.content
      end

      private

      def build_content
        VCS::Content.new(repository: repository)
      end

      def remote_content
        @remote_content ||=
          VCS::RemoteContent
          .create_with(content: build_content)
          .find_or_create_by(
            repository: repository,
            remote_file_id: remote_file_id,
            remote_content_version_id: remote_content_version_id
          )
      end
    end
  end
end
