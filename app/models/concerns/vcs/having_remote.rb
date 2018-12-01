# frozen_string_literal: true

module VCS
  # Adds support for performing actions on the remote
  # Concerning model must implement the #remote_file_id attribute/method.
  module HavingRemote
    extend ActiveSupport::Concern

    included do
      attr_writer :remote
    end

    # Instantiate the remote
    def remote
      @remote ||= remote_class.new(remote_file_id)
    end

    # Reset the remote when calling #reload
    def reload
      reset_remote
      super
    end

    private

    # Reset the remote
    def reset_remote
      @remote = nil
    end

    # The class for the remote
    def remote_class
      'Providers::GoogleDrive::FileSync'.constantize
    end
  end
end
